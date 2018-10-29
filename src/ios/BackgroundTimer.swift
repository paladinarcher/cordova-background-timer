@objc(BackgroundTimer) class BackgroundTimer : CDVPlugin {
    
    var onTimerEventCallbackContext:String?
    let timerSeconds: Int = 30
    
    private var timer: DispatchSourceTimer?;
    
    func getNewTimer() -> DispatchSourceTimer {
        let t = DispatchSource.makeTimerSource()
        t.scheduleRepeating(deadline: .now() + .seconds(self.timerSeconds), interval: .seconds(self.timerSeconds))
        t.setEventHandler(handler: { [weak self] in
            let pr = CDVPluginResult( status: CDVCommandStatus_OK, messageAs: "Timer fired");
            pr!.setKeepCallbackAs(true);
            self?.commandDelegate!.send(pr, callbackId:self?.onTimerEventCallbackContext)
        })
        return t
    }
    
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
            timer?.resume()
        }
        
        timer?.setEventHandler {}
        timer?.cancel()
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
        self.commandDelegate!.run(inBackground: {
            var pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Already started"
            )
            
            self.timer?.cancel()
            self.timer = self.getNewTimer()
            
            self.timer?.resume()
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: "Started Successfully"
            )
            self.commandDelegate!.send(
                pluginResult,
                callbackId: command.callbackId
            )
        })
    }
    @objc(stop:)
    func stop(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: "Already stopped"
        )
        
        if state != .suspended {
            state = .suspended
            timer?.suspend()
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
