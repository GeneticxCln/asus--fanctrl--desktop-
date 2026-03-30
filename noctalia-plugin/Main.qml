import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property var pluginApi: null

  property string pwmBasePath: ""
  property bool hardwareFound: pwmBasePath !== ""
  property int pwm1Speed: 0
  property int pwm3Speed: 0
  property int pwm6Speed: 0
  property real cpuTemp: 0
  property real sysTemp: 0

  // Detection properties
  property int detectionAttempts: 0
  property int maxDetectionAttempts: 5
  property bool detectionInProgress: false
  property string detectionStatus: "Initializing..."

  // Valid PWM channels for this hardware
  readonly property var validChannels: [1, 3, 6]

  // Hardware detection process
  Process {
    id: detectProc
    command: ["/usr/local/bin/asus-fanctrl-detect", "detect"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var output = (typeof text !== "undefined" && text) ? text.trim() : "";
        Logger.i("ASUS Fan Control", "Detection raw output: " + output);
        if (output && output.indexOf("/sys/") === 0 && output.indexOf("\n") === -1) {
          root.pwmBasePath = output;
          root.detectionStatus = "Hardware detected";
          root.detectionInProgress = false;
          Logger.i("ASUS Fan Control", "Hardware found at: " + root.pwmBasePath);
          refreshData();
        } else {
          handleDetectionFailure();
        }
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        handleDetectionFailure();
      }
    }
  }

  function handleDetectionFailure() {
    if (root.detectionAttempts < root.maxDetectionAttempts) {
      root.detectionAttempts++;
      root.detectionStatus = "Hardware not found. Retrying... (" + root.detectionAttempts + "/" + root.maxDetectionAttempts + ")";
      retryTimer.restart();
    } else {
      root.detectionInProgress = false;
      root.detectionStatus = "Hardware not detected - try loading nct6775 module";
      Logger.e("ASUS Fan Control", "Hardware not detected after " + root.maxDetectionAttempts + " attempts.");
    }
  }

  // Timer for detection retries
  Timer {
    id: retryTimer
    interval: 2000
    repeat: false
    onTriggered: {
      detectProc.running = true;
    }
  }

  // Timer for deferred refresh after setFanSpeed
  Timer {
    id: deferredRefreshTimer
    interval: 500
    repeat: false
    onTriggered: {
      refreshData();
    }
  }

  // Timer for deferred detection after module load
  Timer {
    id: deferredDetectionTimer
    interval: 2000
    repeat: false
    onTriggered: {
      startDetection();
    }
  }

  // Sensors process
  Process {
    id: sensorsProc
    command: ["sensors", "-u"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (typeof text !== "undefined" && text) {
          parseSensorsOutput(text);
        }
      }
    }
  }

  // PWM Read Processes
  Process {
    id: pwm1Proc
    command: ["cat", root.pwmBasePath + "/pwm1"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (typeof text !== "undefined" && text) {
          root.pwm1Speed = Math.round((parseInt(text.trim()) * 100) / 255);
        }
      }
    }
  }

  Process {
    id: pwm3Proc
    command: ["cat", root.pwmBasePath + "/pwm3"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (typeof text !== "undefined" && text) {
          root.pwm3Speed = Math.round((parseInt(text.trim()) * 100) / 255);
        }
      }
    }
  }

  Process {
    id: pwm6Proc
    command: ["cat", root.pwmBasePath + "/pwm6"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (typeof text !== "undefined" && text) {
          root.pwm6Speed = Math.round((parseInt(text.trim()) * 100) / 255);
        }
      }
    }
  }

  // Timer to refresh data
  Timer {
    id: refreshTimer
    interval: 2000
    running: root.hardwareFound
    repeat: true
    onTriggered: refreshData()
  }

  Component.onCompleted: {
    // Set initial interval from settings
    if (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.updateInterval) {
      refreshTimer.interval = pluginApi.pluginSettings.updateInterval;
    }
    startDetection();
  }

  function startDetection() {
    if (root.detectionInProgress) return;
    root.detectionAttempts = 0;
    root.detectionInProgress = true;
    root.detectionStatus = "Detecting hardware...";
    detectProc.running = true;
  }

  function loadNct6775Module() {
    root.detectionStatus = "Loading kernel module...";
    Quickshell.execDetached(["pkexec", "/usr/bin/modprobe", "nct6775"]);
    deferredDetectionTimer.restart();
  }

  function refreshData() {
    if (!root.hardwareFound || !root.pwmBasePath) return;
    sensorsProc.running = true;
    pwm1Proc.running = true;
    pwm3Proc.running = true;
    pwm6Proc.running = true;
  }

  function setUpdateInterval(intervalMs) {
    if (intervalMs > 0) {
      refreshTimer.interval = intervalMs;
    }
  }

  function parseSensorsOutput(output) {
    var tctlMatch = output.match(/Tctl:\s*([\d.]+)/);
    if (tctlMatch) root.cpuTemp = parseFloat(tctlMatch[1]);

    var systinMatch = output.match(/SYSTIN:\s*([\d.]+)/);
    if (systinMatch) root.sysTemp = parseFloat(systinMatch[1]);
  }

  function clampValue(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function isValidChannel(channel) {
    return root.validChannels.indexOf(channel) !== -1;
  }

  function setFanSpeed(pwmChannel, percentage) {
    if (!root.hardwareFound) return false;
    if (!isValidChannel(pwmChannel)) {
      Logger.e("ASUS Fan Control", "Invalid PWM channel: " + pwmChannel);
      return false;
    }

    if (isNaN(percentage)) {
      Logger.e("ASUS Fan Control", "Invalid PWM percentage: " + percentage);
      return false;
    }

    percentage = clampValue(Math.round(percentage), 0, 100);
    var pwmValue = Math.round((percentage * 255) / 100);
    var enablePath = root.pwmBasePath + "/pwm" + pwmChannel + "_enable";
    var pwmPath = root.pwmBasePath + "/pwm" + pwmChannel;

    if (enablePath.indexOf("/sys/") !== 0 || pwmPath.indexOf("/sys/") !== 0) {
      Logger.e("ASUS Fan Control", "Invalid hardware path traversal attempted");
      return false;
    }

    Logger.i("ASUS Fan Control", "Setting PWM" + pwmChannel + " to " + percentage + "%");

    Quickshell.execDetached(["pkexec", "/usr/local/bin/asus-fanctrl-detect", "set-all", pwmChannel.toString(), percentage.toString()]);

    // Update settings if API exists
    if (pluginApi && pluginApi.pluginSettings) {
      if (pwmChannel === 1) pluginApi.pluginSettings.pwmChannel1 = percentage;
      else if (pwmChannel === 3) pluginApi.pluginSettings.pwmChannel3 = percentage;
      else if (pwmChannel === 6) pluginApi.pluginSettings.pwmChannel6 = percentage;
      pluginApi.saveSettings();
    }

    deferredRefreshTimer.restart();
    return true;
  }

  function setPreset(mode) {
    if (!root.hardwareFound) return;

    switch(mode) {
      case "silent": 
        Quickshell.execDetached(["pkexec", "/usr/local/bin/asus-fanctrl-detect", "set-all", "1", "30", "3", "30", "6", "30"]);
        break;
      case "quiet": 
        Quickshell.execDetached(["pkexec", "/usr/local/bin/asus-fanctrl-detect", "set-all", "1", "50", "3", "50", "6", "50"]);
        break;
      case "performance": 
        Quickshell.execDetached(["pkexec", "/usr/local/bin/asus-fanctrl-detect", "set-all", "1", "80", "3", "80", "6", "80"]);
        break;
      case "max": 
        Quickshell.execDetached(["pkexec", "/usr/local/bin/asus-fanctrl-detect", "set-all", "1", "100", "3", "100", "6", "100"]);
        break;
      case "auto":
        Quickshell.execDetached(["pkexec", "/usr/local/bin/asus-fanctrl-detect", "set-enable-all", "1", "5", "3", "5", "6", "5"]);
        break;
    }
    deferredRefreshTimer.restart();
  }

  IpcHandler {
    target: "plugin:asus-fan-control"

    function getStatus() {
      return JSON.stringify({
        cpuTemp: root.cpuTemp,
        pwm1Speed: root.pwm1Speed,
        pwm3Speed: root.pwm3Speed,
        pwm6Speed: root.pwm6Speed,
        found: root.hardwareFound,
        detectionStatus: root.detectionStatus
      });
    }

    function setPwm(channel, speed) {
      var ch = parseInt(channel);
      if (!isValidChannel(ch)) {
        return "ERROR: invalid channel. Allowed: " + root.validChannels.join(", ");
      }
      var spd = clampValue(parseInt(speed), 0, 100);
      setFanSpeed(ch, spd);
      return "OK";
    }

    function setSilent() { setPreset("silent"); return "OK"; }
    function setQuiet() { setPreset("quiet"); return "OK"; }
    function setPerformance() { setPreset("performance"); return "OK"; }
    function setMax() { setPreset("max"); return "OK"; }
    function setAuto() { setPreset("auto"); return "OK"; }

    function retryDetection() {
        startDetection();
        return "OK";
    }

    function openPanel() {
      if (pluginApi) {
        pluginApi.withCurrentScreen(function(screen) {
          pluginApi.openPanel(screen);
        });
        return "OK";
      }
      return "FAILED";
    }
  }
}
