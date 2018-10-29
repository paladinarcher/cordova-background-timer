@objc(BackgroundTimer) class BackgroundTimer : CDVPlugin {
    
    static var onTimerEventCallbackContext:String?
    static let timerSeconds: Int = 10
    
    private static var timer: DispatchSourceTimer?;
    
    func getNewTimer() -> DispatchSourceTimer {
        let t = DispatchSource.makeTimerSource()
        t.scheduleRepeating(deadline: .now() + .seconds(BackgroundTimer.timerSeconds), interval: .seconds(BackgroundTimer.timerSeconds))
        t.setEventHandler(handler: { [weak self] in
            print("starting running the handler")
            let pr = CDVPluginResult( status: CDVCommandStatus_OK, messageAs: "Timer fired");
            pr!.setKeepCallbackAs(true);
            self?.commandDelegate!.send(pr, callbackId:BackgroundTimer.onTimerEventCallbackContext)
            print("done running the handler")
        })
        return t
    }
    
    private enum State {
        case suspended
        case resumed
    }
    
    private static var state: State = .suspended
    
    @objc(onTimerEvent:)
    func onTimerEvent(command: CDVInvokedUrlCommand) {
        BackgroundTimer.onTimerEventCallbackContext = command.callbackId
        self.commandDelegate.run(inBackground: {
            let pluginResult:CDVPluginResult = CDVPluginResult(status:CDVCommandStatus_NO_RESULT)
            pluginResult.setKeepCallbackAs(true)
            self.commandDelegate!.send(pluginResult, callbackId:command.callbackId)
        })
    }
    @objc(start:)
    func start(command: CDVInvokedUrlCommand) {
        self.commandDelegate!.run(inBackground: { [weak self] in
            print("starting start")
            var pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "Already started"
            )
            print("cancelling old and creating new")
            BackgroundTimer.timer?.cancel()
            BackgroundTimer.timer = self?.getNewTimer()
            print("starting new timer")
            BackgroundTimer.timer?.resume()
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: "Started Successfully"
            )
            print("returning to JS")
            self?.commandDelegate!.send(
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
        
        if BackgroundTimer.state != .suspended {
            BackgroundTimer.state = .suspended
            BackgroundTimer.timer?.suspend()
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
