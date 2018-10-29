@objc(BackgroundTimer) class BackgroundTimer : CDVPlugin {
    
    var onTimerEventCallbackContext:String?
    let timerInterval: TimeInterval = 9
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()
        t.scheduleRepeating(deadline: .now() + self.timerInterval, interval: self.timerInterval)
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
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        if state != .resumed {
            state = .resumed
            timer.resume()
        }
        
        timer.setEventHandler {}
        timer.cancel()
        
        eventHandler = nil
    }
    
    @objc(onTimerEvent:)
    func onTimerEvent(command: CDVInvokedUrlCommand) {
        self.onTimerEventCallbackContext = command.callbackId
        self.commandDelegate.run(inBackground: {
            let pluginResult:CDVPluginResult = CDVPluginResult(status:CDVCommandStatus_NO_RESULT)
            pluginResult.setKeepCallbackAs(true)
            self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
        })
    }
    @objc(start:)
    func start(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: "Already started"
        )
        
        self.eventHandler = { [weak self] in
            let pluginResult = CDVPluginResult( status: CDVCommandStatus_OK, messageAs: "Timer fired");
            pluginResult!.setKeepCallbackAs(true);
            self?.commandDelegate!.send(pluginResult, callbackId:self?.onTimerEventCallbackContext)
        }
        
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
