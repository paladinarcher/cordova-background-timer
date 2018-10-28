@objc(BackgroundTimer) class BackgroundTimer : CDVPlugin {

  let onTimerEventCommands: [String] = []
  let timerInterval: TimeInterval = 9

  private lazy var timer: DispatchSourceTimer = {
    let t = DispatchSource.makeTimerSource()
    t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
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
      resume()
      eventHandler = nil
  }

  @objc(echo:)
  func echo(command: CDVInvokedUrlCommand) {
    var pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR
    )

    let msg = command.arguments[0] as? String ?? ""

    if msg.characters.count > 0 {
      let toastController: UIAlertController =
        UIAlertController(
          title: "",
          message: msg,
          preferredStyle: .alert
        )
      
      self.viewController?.present(
        toastController,
        animated: true,
        completion: nil
      )

      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        toastController.dismiss(
            animated: true,
            completion: nil
        )
      }
        
      pluginResult = CDVPluginResult(
        status: CDVCommandStatus_OK,
        messageAs: msg
      )
    }

    self.commandDelegate!.send(
      pluginResult,
      callbackId: command.callbackId
    )
  }
  @objc(onTimerEvent:)
  func onTimerEvent(command: CDVInvokedUrlCommand) {
    onTimerEventCommands.append(command.callbackId);
  }
  func fireOnTimerEvent() {
    var pluginResult = CDVPluginResult(
      status: CDVCommandStatus_OK
      setKeepCallbackAsBool: YES
    )
    for itm in onTimerEventCommands {
      self?.commandDelegate!.send(
        pluginResult,
        callbackId: item
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