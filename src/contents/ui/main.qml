import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Model danych dostępny w całym pliku
    ListModel {
        id: radioModel
    }

    // Silnik odtwarzania
    MediaPlayer {
        id: mediaPlayer
        audioOutput: AudioOutput {
            id: audioOutput
            volume: 1.0
        }
        source: ""
    }

    compactRepresentation: Kirigami.Icon {
        source: "radio"
        opacity: mouseArea.containsMouse ? 1.0 : 0.8
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: 350
        Layout.minimumHeight: 450
        spacing: 10

        // Nagłówek i wyszukiwarka
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: "Szukaj stacji radiowych..."
                onAccepted: root.searchStations(text)
            }
            PlasmaComponents.Button {
                icon.name: "edit-find"
                onClicked: root.searchStations(searchField.text)
            }
        }

        // Lista wyników
        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: radioModel

            delegate: PlasmaComponents.ItemDelegate {
                width: resultsList.width
                highlighted: ListView.isCurrentItem

                contentItem: RowLayout {
                    spacing: 10

                    Kirigami.Icon {
                        source: model.favicon && model.favicon !== "" ? model.favicon : "audio-x-generic"
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: model.name
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: (model.country || "Nieznany") + (model.tags ? " | " + model.tags : "")
                            font.pixelSize: 10
                            opacity: 0.6
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                onClicked: {
                    resultsList.currentIndex = index
                    mediaPlayer.source = model.url
                    mediaPlayer.play()
                    console.log("Odtwarzanie: " + model.name)
                }
            }

            // Informacja o braku wyników
            PlasmaComponents.Label {
                anchors.centerIn: parent
                text: "Brak wyników. Wpisz coś i szukaj!"
                visible: radioModel.count === 0
                opacity: 0.5
            }
        }

        // Prosty pasek sterowania na dole
        RowLayout {
            Layout.fillWidth: true
            visible: mediaPlayer.playbackState === MediaPlayer.PlayingState

            PlasmaComponents.Label {
                text: "Gra: " + (resultsList.currentItem ? resultsList.model.get(resultsList.currentIndex).name : "")
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            PlasmaComponents.Button {
                icon.name: "media-playback-stop"
                onClicked: mediaPlayer.stop()
            }
        }
    }

    function searchStations(query) {
        if (query.length < 2) return;

        radioModel.clear();
        // API Radio-Browser (używamy de1 jako stabilnego serwera)
        const url = "https://de1.api.radio-browser.info/json/stations/byname/" + encodeURIComponent(query);

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                const response = JSON.parse(xhr.responseText);
                for (let i = 0; i < Math.min(response.length, 40); i++) {
                    radioModel.append({
                        name: response[i].name,
                        url: response[i].url_resolved,
                        favicon: response[i].favicon,
                        country: response[i].country,
                        tags: response[i].tags
                    });
                }
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }
}
