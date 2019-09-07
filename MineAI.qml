// you can also run this via "qml-qt5 MineAI.qml"

import QtQuick 2.7
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.12
//todo: mark wrong flags after game lost

ApplicationWindow {
    id: window
    visible: true
    visibility: "Windowed"
    width: gameGrid.width
    height: mainCol.height
    color: "grey"
    title: "MineAI"

    QtObject {
        id: game
        property var difficulties: {
            "easy" : [9, 9, 10],
            "advanced": [16, 16, 40],
            "expert":   [16, 30, 99],
            "test":     [5, 5, 24]
        }

        // todo: maybe set these also on startGame
        property var selectedDifficulty: difficulties["easy"]

        // must always match the current game, stop game if changed ?!
        property int rows: selectedDifficulty[0]
        property int columns: selectedDifficulty[1]
        property int mines: selectedDifficulty[2]

        property int flagsLeft // set on startGame
        property int unrevealedFields // dito
        onUnrevealedFieldsChanged: {
            console.log(unrevealedFields)
        }

        property bool started: false
        property bool won: !lost && unrevealedFields - mines === 0
        property bool lost: steppedOnMineIndex != -1
        property bool ended: won || lost
        property int steppedOnMineIndex: -1
    }

    Column {
        id: mainCol
        RowLayout {
            width: gameGrid.width
            Text {
                text: "Time"
            }

            Button {
                Layout.fillWidth: true
                text: if (game.lost) {
                          "X("
                      } else if (game.won) {
                          "8-)"
                      } else {
                          ":)"
                      }

                onClicked: {
                    startGame();
                }
            }

            Text {
                text: game.flagsLeft
            }
        }
        GridLayout {
            id: gameGrid
            columns: game.columns

            Repeater {
                id: fieldRepeater
                model: game.columns * game.rows

                Rectangle {
                    property bool mine
                    property bool flagged
                    property bool revealed
                    property int adjacentMines
                    property int adjacentFlags
                    property int adjacentHidden // i.e. flagged or untouched
                    width: 30
                    height: width

                    color:
                        if (game.steppedOnMineIndex === index) {
                            "red"
                        } else if (revealed || (game.lost && mine)){
                            "black"
                        } else {
                            "green"
                        }

                    border {
                        color: "black"
                        width: 2
                    }

                    Text {
                        text: parent.adjacentHidden
                        font.pixelSize: 10
                        color: "white"
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text:
                            if (parent.flagged || (game.won && parent.mine)) {
                                "F";
                            } else if (parent.revealed) {
                                if (mine) {
                                    "X";
                                } else {
                                    if (parent.adjacentMines > 0) {
                                        parent.adjacentMines
                                    } else {
                                        ""
                                    }
                                }
                            } else if (game.lost && mine){
                                "M"
                            } else {
                                ""
                            }

                        color:
                            switch (text) {
                            case "1": return "#05ff03";
                            case "2": return "white";
                            case "3": return "#0cffff"
                            case "4": return "#ffff03";
                            case "5": return "#0800ff";
                            case "6": return "pink";
                            case "7": return "pink";
                            case "F": return "#ff0101";
                            default: return "white";
                            }

                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: {
                            if (game.ended || parent.revealed) {
                                return
                            }

                            if (mouse.button & Qt.RightButton) {
                                toggleFlag()
                            } else if (!parent.flagged){
                                reveal();
                            }
                        }
                    }

                    function toggleFlag() {
                        flagged = !flagged;
                        var flagDelta = flagged ? 1 : -1
                        game.flagsLeft -= flagDelta

                        // --- AI reveal if flag matches numbers ---
                        updateNeighborsByIndex(index, function(field) {
                            field.adjacentFlags += flagDelta
                            field.aiFlagMatchNumber();
                        });
                    }

                    function aiFlagMatchNumber() {
                        if (!revealed || adjacentFlags !== adjacentMines) {
                            return;
                        }
                        updateNeighborsByIndex(index, function (field) {
                           if (!field.flagged && !field.revealed) {
                               field.reveal()
                           }
                        });
                    }

                    function aiHiddenMatchNumber() {
                        if (!revealed ||
                                adjacentHidden !== adjacentMines) {
                            return;
                        }
                        updateNeighborsByIndex(index, function (field) {
                           if (!field.flagged && !field.revealed) {
                               field.toggleFlag()
                           }
                        });
                    }

                    function reveal() {
                        if (flagged || revealed || game.ended) {
                            return;
                        }
                        revealed = true
                        game.unrevealedFields--
                        console.warn(game.unrevealedFields)
                        if (mine) {
                            game.steppedOnMineIndex = index;
                        } else if (adjacentMines === 0) {
                            updateNeighborsByIndex(index, function(field) {
                                if (field.flagged) {
                                    return;
                                }
                                field.reveal();
                            });
                        }
                        updateNeighborsByIndex(index, function (field) {
                            field.adjacentHidden--;
                            field.aiHiddenMatchNumber();
                        })
                        aiFlagMatchNumber();
                    }
                }
            }
        }

        Component.onCompleted: {
            startGame()
        }

    }


    function startGame() {
        for (var i = 0; i < game.columns * game.rows; i++) {
            var field = fieldRepeater.itemAt(i)
            field.mine = false
            field.revealed = false
            field.flagged = false
            field.adjacentMines = 0
            field.adjacentFlags = 0

            var x = i % game.columns;
            var y = Math.floor(i / game.columns);
            var adjacentHidden = 8
            if (x === 0 || x === game.columns - 1) {
                adjacentHidden -= 3;
            }
            if (y === 0 || y === game.rows - 1) {
                adjacentHidden -= 3;
            }
            field.adjacentHidden = Math.max(adjacentHidden, 3) // account for corner
        }
        game.flagsLeft = game.mines
        game.unrevealedFields = game.rows * game.columns
        game.started = false
        game.steppedOnMineIndex = -1

        for (var mine = 0; mine < game.mines; mine++) {
            while (true) {
                x = getRandomInt(game.columns);
                y = getRandomInt(game.rows);
                if (!getField(x, y).mine) {
                    getField(x, y).mine = true
                    updateNeighbors(x, y, function(field) {
                        field.adjacentMines++;
                    });
                    break;
                }
            }
        }
    }
    function updateNeighborsByIndex(index, f) {
        var x = index % game.columns;
        var y = Math.floor(index / game.columns);
        updateNeighbors(x, y, f);
    }

    function updateNeighbors(x, y, f) {
        for (var xd = -1; xd <= 1; xd++) {
            for (var yd = -1; yd <= 1; yd++) {
                if (xd == 0 && yd == 0) {
                    continue;
                }
                var field = getField(x + xd, y + yd);
                if (field) {
                    f(field);
                }
            }
        }
    }

    function getField(x, y) {
        if (x < 0 || x >= game.columns || y < 0 || y >= game.rows) {
            return null;
        }

        return fieldRepeater.itemAt(x + game.columns * y)
    }

    function getRandomInt(max) {
        return Math.floor(Math.random() * Math.floor(max));
    }
}
