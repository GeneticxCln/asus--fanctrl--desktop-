import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0
  property bool hovered: false

  readonly property string screenName: screen ? screen.name : ""
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // Get data from Main.qml via pluginApi
  readonly property real cpuTemp: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance.cpuTemp : 0
  readonly property int pwm1Speed: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance.pwm1Speed : 0

  visible: true
  opacity: 1.0

  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)

  implicitWidth: isVertical ? capsuleHeight : layout.implicitWidth + Style.marginS * 2
  implicitHeight: isVertical ? layout.implicitHeight + Style.marginS * 2 : capsuleHeight

  // Widget capsule
  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: isVertical ? capsuleHeight : layout.implicitWidth + Style.marginS * 2
    height: isVertical ? layout.implicitHeight + Style.marginS * 2 : capsuleHeight
    radius: Style.radiusM
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    // Background color with temperature tint
    color: {
      var baseColor = root.hovered ? (typeof Color !== "undefined" ? Color.mHover : "#33ffffff") : Style.capsuleColor;
      if (root.cpuTemp >= 70) return Qt.rgba(0.93, 0.27, 0.27, 0.4);
      if (root.cpuTemp >= 50) return Qt.rgba(0.98, 0.75, 0.14, 0.3);
      if (root.cpuTemp > 0) return Qt.rgba(0.29, 0.87, 0.5, 0.25);
      return baseColor;
    }

    Item {
      id: layout
      anchors.centerIn: parent
      implicitWidth: grid.implicitWidth
      implicitHeight: grid.implicitHeight

      GridLayout {
        id: grid
        columns: root.isVertical ? 1 : 2
        rowSpacing: Style.marginS
        columnSpacing: Style.marginS

        NIcon {
          Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
          icon: "car-fan"
          color: root.hovered ? (typeof Color !== "undefined" ? Color.mOnHover : "#ffffff") : (typeof Color !== "undefined" ? Color.mOnSurface : "#ffffff")
        }

        NText {
          Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
          text: root.cpuTemp > 0 ? root.cpuTemp.toFixed(0) + "°" : "--"
          color: getTempColor()
          font.bold: true
          pointSize: root.barFontSize
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    onEntered: {
      root.hovered = true;
    }

    onExited: {
      root.hovered = false;
      TooltipService.hide();
    }

    onPressed: function(mouse) {
      if (mouse.button == Qt.LeftButton && root.pluginApi) {
        root.pluginApi.openPanel(root.screen);
      }
    }
  }

  function getTempColor() {
    if (root.cpuTemp >= 70) return (typeof Color !== "undefined" ? Color.mError : "#f44336");
    if (root.cpuTemp >= 50) return "#ff9800";
    if (root.cpuTemp > 0) return "#4caf50";
    return (typeof Color !== "undefined" ? Color.mOnSurface : "#ffffff");
  }
}
