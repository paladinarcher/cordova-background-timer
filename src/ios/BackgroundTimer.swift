@objc(BackgroundTimer) class BackgroundTimer : CDVPlugin {

  var onTimerEventCommands: [String] = []
  let timerInterval: TimeInterval = 9

  private lazy var timer: DispatchSourceTimer = {
    let t = DispatchSource.makeTimerSource()
    t.scheduleRepeating(deadline: <#T##DispatchTime#>, interval: <#T##DispatchTimeInterval#>)
    t.setEventHandler(handler: { [weak self] in
      self?.eventHandler?()
    })
    return t
  }()

  var eventHandler: (() -> Void)?

  private enum State {
      case suspended
      case resumed
  }

  private var state: State = .suspended

  deinit {
      timer.setEventHandler {}
      timer.cancel()
      /*
        If the timer is suspended, calling cancel without resuming
        triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
        */
      if state != .resumed {
          state = .resumed
          timer.resume()
      }
      eventHandler = nil
  }

  @objc(onTimerEvent:)
  func onTimerEvent(command: CDVInvokedUrlCommand) {
    let cmd = command.callbackId;
    onTimerEventCommands.append(cmd!);
  }
  func fireOnTimerEvent() {
    let pluginResult = CDVPluginResult(
      status: CDVCommandStatus_OK
    )
    pluginResult!.setKeepCallbackAs(true)
    for itm in onTimerEventCommands {
      self.commandDelegate!.send(
        pluginResult,
        callbackId: itm
      )
    }
  }
  @objc(start:)
  func start(command: CDVInvokedUrlCommand) {
    var pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR,
      messageAs: "Already started"
    )

    if state != .resumed {
      state = .resumed
      timer.resume()
      pluginResult = CDVPluginResult(
        status: CDVCommandStatus_OK,
        messageAs: "Started Successfully"
      )
    }

    self.commandDelegate!.send(
      pluginResult,
      callbackId: command.callbackId
    )
  }
  @objc(stop:)
  func stop(command: CDVInvokedUrlCommand) {
    var pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR,
      messageAs: "Already stopped"
    )

    if state != .suspended {
      state = .suspended
      timer.suspend()
      pluginResult = CDVPluginResult(
        status: CDVCommandStatus_OK,
        messageAs: "Stopped Successfully"
      )
    }

    self.commandDelegate!.send(
      pluginResult,
      callbackId: command.callbackId
    )
  }
}
