import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    spacing: 10
    width: 400
    height: 500

    // 1. Pole wyszukiwania
    PlasmaComponents.TextField {
        id: searchField
        Layout.fillWidth: true
        placeholderText: "Wpisz nazwę stacji (np. Rock)..."
        onAccepted: searchStations(text) // Szukaj po naciśnięciu Enter
    }

    // 2. Przycisk wyzwalający
    PlasmaComponents.Button {
        text: "Szukaj stacji"
        Layout.fillWidth: true
        onClicked: searchStations(searchField.text)
    }

    // 3. Lista wyników
    ListView {
        id: resultsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: ListModel { id: radioModel }

        delegate: PlasmaComponents.ListItem {
            width: resultsList.width
            contentItem: ColumnLayout {
                PlasmaComponents.Label {
                    text: model.name
                    font.bold: true
                }
                PlasmaComponents.Label {
                    text: model.country + " | " + model.tags
                    font.pixelSize: 10
                    opacity: 0.7
                }
            }
            onClicked: {
                console.log("Wybrano stację: " + model.url)
                // Tutaj dodasz logikę odtwarzania (MediaPlayer)
            }
        }
    }

    // 4. Logika pobierania danych (JavaScript)
    function searchStations(query) {
        if (query.length < 2) return;

        radioModel.clear();
        const url = "https://de1.api.radio-browser.info/json/stations/byname/" + encodeURIComponent(query);

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    const response = JSON.parse(xhr.responseText);
                    for (let i = 0; i < response.length; i++) {
                        radioModel.append({
                            name: response[i].name,
                            url: response[i].url_resolved,
                            country: response[i].country,
                            tags: response[i].tags
                        });
                    }
                } else {
                    console.error("Błąd pobierania danych: " + xhr.status);
                }
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }
}
