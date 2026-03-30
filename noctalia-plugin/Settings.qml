import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NPanel {
  id: root

  property var pluginApi: null

  property int pwm1Value: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings.pwmChannel1 : 50
  property int pwm3Value: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings.pwmChannel3 : 50
  property int pwm6Value: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings.pwmChannel6 : 50

  title: "ASUS Fan Control Settings"
  icon: "car-fan"
  preferredWidth: 400
  preferredHeight: 500

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    NText {
      text: "Update Interval (ms)"
      pointSize: 10
    }

    NSpinBox {
      Layout.fillWidth: true
      from: 500
      to: 10000
      stepSize: 500
      value: (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings.updateInterval : 2000

      onValueModified: {
        if (pluginApi) {
          pluginApi.pluginSettings.updateInterval = value;
          pluginApi.saveSettings();
          if (pluginApi.mainInstance && typeof pluginApi.mainInstance.setUpdateInterval === "function") {
            pluginApi.mainInstance.setUpdateInterval(value);
          }
        }
      }
    }

    NText {
      text: "Default PWM Values"
      pointSize: 10
      Layout.topMargin: 16
    }

    // PWM1
    RowLayout {
      Layout.fillWidth: true
      NText {
        text: "PWM1:"
        width: 60
      }
      NSlider {
        id: pwm1Slider
        Layout.fillWidth: true
        from: 0
        to: 100
        value: root.pwm1Value
      }
      NText {
        text: Math.round(pwm1Slider.value) + "%"
        width: 40
      }
    }

    // PWM3
    RowLayout {
      Layout.fillWidth: true
      NText {
        text: "PWM3:"
        width: 60
      }
      NSlider {
        id: pwm3Slider
        Layout.fillWidth: true
        from: 0
        to: 100
        value: root.pwm3Value
      }
      NText {
        text: Math.round(pwm3Slider.value) + "%"
        width: 40
      }
    }

    // PWM6
    RowLayout {
      Layout.fillWidth: true
      NText {
        text: "PWM6:"
        width: 60
      }
      NSlider {
        id: pwm6Slider
        Layout.fillWidth: true
        from: 0
        to: 100
        value: root.pwm6Value
      }
      NText {
        text: Math.round(pwm6Slider.value) + "%"
        width: 40
      }
    }

    Item { Layout.fillHeight: true }

    NButton {
      text: "Apply Now"
      Layout.alignment: Qt.AlignHCenter
      onClicked: {
        if (pluginApi && pluginApi.mainInstance) {
          pluginApi.mainInstance.setFanSpeed(1, Math.round(pwm1Slider.value));
          pluginApi.mainInstance.setFanSpeed(3, Math.round(pwm3Slider.value));
          pluginApi.mainInstance.setFanSpeed(6, Math.round(pwm6Slider.value));
          ToastService.showNotification("Fan speeds applied", false);
        }
      }
    }

    NButton {
      text: "Reset to Defaults"
      Layout.alignment: Qt.AlignHCenter
      onClicked: {
        if (pluginApi) {
          root.pwm1Value = 50;
          root.pwm3Value = 50;
          root.pwm6Value = 50;
          pluginApi.pluginSettings.pwmChannel1 = 50;
          pluginApi.pluginSettings.pwmChannel3 = 50;
          pluginApi.pluginSettings.pwmChannel6 = 50;
          pluginApi.pluginSettings.updateInterval = 2000;
          pluginApi.saveSettings();
          ToastService.showNotification("Settings reset", false);
        }
      }
    }
  }

  // Sync values via debounce to prevent update spam
  Timer {
    id: applyDebounce
    interval: 300
    repeat: false
    onTriggered: {
      if (!pluginApi) return;
      
      root.pwm1Value = Math.round(pwm1Slider.value);
      root.pwm3Value = Math.round(pwm3Slider.value);
      root.pwm6Value = Math.round(pwm6Slider.value);
      
      pluginApi.pluginSettings.pwmChannel1 = root.pwm1Value;
      pluginApi.pluginSettings.pwmChannel3 = root.pwm3Value;
      pluginApi.pluginSettings.pwmChannel6 = root.pwm6Value;
      pluginApi.saveSettings();
      
      if (pluginApi.mainInstance) {
        pluginApi.mainInstance.setFanSpeed(1, root.pwm1Value);
        pluginApi.mainInstance.setFanSpeed(3, root.pwm3Value);
        pluginApi.mainInstance.setFanSpeed(6, root.pwm6Value);
      }
    }
  }

  Connections {
    target: pwm1Slider
    function onValueChanged() { applyDebounce.restart(); }
  }

  Connections {
    target: pwm3Slider
    function onValueChanged() { applyDebounce.restart(); }
  }

  Connections {
    target: pwm6Slider
    function onValueChanged() { applyDebounce.restart(); }
  }
}
