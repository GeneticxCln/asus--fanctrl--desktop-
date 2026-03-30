import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  // SmartPanel required properties
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 450 * Style.uiScaleRatio
  property real contentPreferredHeight: 520 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  anchors.fill: parent

  // Get data from Main.qml
  readonly property real cpuTemp: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance.cpuTemp : 0
  readonly property real sysTemp: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance.sysTemp : 0
  readonly property int pwm1Speed: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance.pwm1Speed : 0
  readonly property int pwm3Speed: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance.pwm3Speed : 0
  readonly property int pwm6Speed: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance.pwm6Speed : 0
  readonly property bool hardwareFound: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance.hardwareFound : false
  readonly property string detectionStatus: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance.detectionStatus : "Unknown"

  // Local slider values for bidirectional binding
  property int pwm1SliderValue: pwm1Speed
  property int pwm3SliderValue: pwm3Speed
  property int pwm6SliderValue: pwm6Speed

  // Sync slider values when Main.qml data changes
  onPwm1SpeedChanged: pwm1SliderValue = pwm1Speed
  onPwm3SpeedChanged: pwm3SliderValue = pwm3Speed
  onPwm6SpeedChanged: pwm6SliderValue = pwm6Speed

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      anchors.margins: Style.marginS
      color: Style.capsuleColor
      radius: Style.radiusL
      border.color: Style.capsuleBorderColor
      border.width: Style.capsuleBorderWidth

      Column {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginM

        // Header
        Row {
          width: parent.width
          spacing: Style.marginM

          NIcon {
            icon: "car-fan"
            width: 24
            height: 24
            color: (typeof Color !== "undefined" ? Color.mOnSurface : "#ffffff")
          }

          NText {
            text: "ASUS Fan Control"
            font.bold: true
            pointSize: 14
          }

          NText {
            visible: root.hardwareFound
            text: "(Connected)"
            color: "#4caf50"
            font.italic: true
            pointSize: 10
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Style.capsuleBorderColor
        }
        
        // Detection Status UI
        Rectangle {
           visible: !root.hardwareFound
           width: parent.width
           height: errorColumn.height + Style.marginL * 2
           color: (typeof Color !== "undefined" ? Qt.alpha(Color.mError, 0.15) : "#33ff0000")
           radius: Style.radiusM
           
           Column {
              id: errorColumn
              anchors.centerIn: parent
              width: parent.width - Style.marginL * 2
              spacing: Style.marginM
              
              NText {
                 text: "Hardware Not Detected"
                 color: (typeof Color !== "undefined" ? Color.mError : "#f44336")
                 font.bold: true
                 anchors.horizontalCenter: parent.horizontalCenter
              }
              
              NText {
                 text: root.detectionStatus
                 color: (typeof Color !== "undefined" ? Color.mOnSurface : "#ffffff")
                 wrapMode: Text.WordWrap
                 width: parent.width
                 horizontalAlignment: Text.AlignHCenter
                 pointSize: 10
              }
              
              Row {
                 anchors.horizontalCenter: parent.horizontalCenter
                 spacing: Style.marginM
                 
                 NButton {
                    text: "Retry"
                    onClicked: {
                        if (pluginApi && pluginApi.mainInstance && pluginApi.mainInstance.startDetection) {
                            pluginApi.mainInstance.startDetection();
                        }
                    }
                 }
                 
                 NButton {
                    text: "Load Module"
                    onClicked: {
                        if (pluginApi && pluginApi.mainInstance && pluginApi.mainInstance.loadNct6775Module) {
                            pluginApi.mainInstance.loadNct6775Module();
                        }
                    }
                 }
              }
           }
        }

        // Temperature section
        Rectangle {
          visible: root.hardwareFound
          width: parent.width
          height: tempColumn.height + Style.marginM * 2
          color: "transparent"

          Column {
            id: tempColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NText {
              text: "🌡️ Temperatures"
              font.bold: true
              pointSize: 12
            }

            Row {
              width: parent.width
              spacing: Style.marginM

              NText {
                text: "CPU:"
                width: 80
              }

              NText {
                text: cpuTemp > 0 ? cpuTemp.toFixed(1) + "°C" : "N/A"
                font.bold: true
                color: {
                  if (cpuTemp < 50) return "#4caf50";
                  if (cpuTemp < 70) return "#ff9800";
                  return (typeof Color !== "undefined" ? Color.mError : "#f44336");
                }
              }
            }

            Row {
              width: parent.width
              spacing: Style.marginM

              NText {
                text: "System:"
                width: 80
              }

              NText {
                text: sysTemp > 0 ? sysTemp.toFixed(1) + "°C" : "N/A"
                color: (typeof Color !== "undefined" ? Color.mOnSurface : "#ffffff")
              }
            }
          }
        }

        Rectangle {
          visible: root.hardwareFound
          width: parent.width
          height: 1
          color: Style.capsuleBorderColor
        }

        // PWM Control section
        Rectangle {
          visible: root.hardwareFound
          width: parent.width
          height: pwmColumn.height + Style.marginM * 2
          color: "transparent"

          Column {
            id: pwmColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NText {
              text: "🔧 Fan Speed Control"
              font.bold: true
              pointSize: 12
            }

            // PWM1
            Row {
              width: parent.width
              spacing: Style.marginM

              NText {
                text: "PWM1 (CPU)"
                width: 80
              }

              NSlider {
                id: pwm1Slider
                width: parent.width - 150
                from: 0
                to: 100
                value: root.pwm1SliderValue
                enabled: root.hardwareFound
                onValueChanged: { root.pwm1SliderValue = value; applyDebounce.restart() }
              }

              NText {
                text: Math.round(pwm1Slider.value) + "%"
                width: 40
              }
            }

            // PWM3
            Row {
              width: parent.width
              spacing: Style.marginM

              NText {
                text: "PWM3"
                width: 80
              }

              NSlider {
                id: pwm3Slider
                width: parent.width - 150
                from: 0
                to: 100
                value: root.pwm3SliderValue
                enabled: root.hardwareFound
                onValueChanged: { root.pwm3SliderValue = value; applyDebounce.restart() }
              }

              NText {
                text: Math.round(pwm3Slider.value) + "%"
                width: 40
              }
            }

            // PWM6
            Row {
              width: parent.width
              spacing: Style.marginM

              NText {
                text: "PWM6"
                width: 80
              }

              NSlider {
                id: pwm6Slider
                width: parent.width - 150
                from: 0
                to: 100
                value: root.pwm6SliderValue
                enabled: root.hardwareFound
                onValueChanged: { root.pwm6SliderValue = value; applyDebounce.restart() }
              }

              NText {
                text: Math.round(pwm6Slider.value) + "%"
                width: 40
              }
            }
          }
        }

        Rectangle {
          visible: root.hardwareFound
          width: parent.width
          height: 1
          color: Style.capsuleBorderColor
        }

        // Quick Presets
        Rectangle {
          visible: root.hardwareFound
          width: parent.width
          height: presetRow.height + Style.marginM * 2
          color: "transparent"

          Row {
            id: presetRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.marginM

            NButton {
              text: "🔇 Silent"
              onClicked: setPreset("silent")
              enabled: root.hardwareFound
            }

            NButton {
              text: "🔉 Quiet"
              onClicked: setPreset("quiet")
              enabled: root.hardwareFound
            }

            NButton {
              text: "🔊 Perf"
              onClicked: setPreset("performance")
              enabled: root.hardwareFound
            }

            NButton {
              text: "🚀 Max"
              onClicked: setPreset("max")
              enabled: root.hardwareFound
            }

            NButton {
              text: "🔄 Auto"
              onClicked: setAutoMode()
              enabled: root.hardwareFound
            }
          }
        }

        Item {
          width: parent.width
          height: Math.max(0, parent.height - (root.hardwareFound ? (tempColumn.height + pwmColumn.height + presetRow.height + Style.marginM * 10) : (errorColumn.height + Style.marginM * 8)))
        }

        NText {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.hardwareFound ? "Drag slider to adjust fan speed" : "Hardware must be detected to use controls"
          pointSize: 10
          opacity: 0.6
        }
      }
    }
  }

  function setFanSpeed(pwmChannel, percentage) {
    if (pluginApi && pluginApi.mainInstance) {
      pluginApi.mainInstance.setFanSpeed(pwmChannel, percentage);
    }
  }

  function setPreset(mode) {
    if (pluginApi && pluginApi.mainInstance) {
      // Update sliders immediately for visual feedback
      var presetValues = {"silent": 30, "quiet": 50, "performance": 80, "max": 100};
      if (presetValues[mode] !== undefined) {
        root.pwm1SliderValue = presetValues[mode];
        root.pwm3SliderValue = presetValues[mode];
        root.pwm6SliderValue = presetValues[mode];
      }
      pluginApi.mainInstance.setPreset(mode);
    }
  }

  function setAutoMode() {
    if (pluginApi && pluginApi.mainInstance) {
      pluginApi.mainInstance.setPreset("auto");
      ToastService.showNotification("Fans set to automatic mode", false);
    }
  }

  Timer {
    id: applyDebounce
    interval: 300
    repeat: false
    onTriggered: {
      setFanSpeed(1, root.pwm1SliderValue);
      setFanSpeed(3, root.pwm3SliderValue);
      setFanSpeed(6, root.pwm6SliderValue);
    }
  }
}
