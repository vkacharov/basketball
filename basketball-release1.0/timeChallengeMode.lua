local timeChallengeMode={key="timeChallengeMode"}

function timeChallengeMode:new(options) 
	o = options or {}
	setmetatable(o, self)
    self.__index = self
	return o
end

local function toTime(seconds)
	local mins = math.floor(seconds/60)
	local secs = seconds % 60
	
	local ts = tostring(secs)
	if(secs < 10) then 
		ts = "0" .. ts
	end
	
	local result = tostring(mins) .. ":" .. ts
	mins = nil
	secs = nil
	ts = nil
	return result
end


function timeChallengeMode:onStageBegin(textField)
	self.timeLeft = self.seconds
	
	local tm = toTime(self.timeLeft)
	textField.text = tm
	self.timerText = textField
	tm = nil
	
	local listener = function(event)
		self.timeLeft = self.timeLeft - 1
		self.timerText.text = toTime(self.timeLeft)
		if(self.timeLeft == 0) then 
			if(self.onChallengeComplete) then 
				self.onChallengeComplete()
			end
		end
	end
	
	self.timerId = timer.performWithDelay(1000, listener, self.seconds)
end

function timeChallengeMode:pause()
	timer.pause(self.timerId)
end

function timeChallengeMode:resume()
	timer.resume(self.timerId)
end

function timeChallengeMode:onRoundStart(params)

end

function timeChallengeMode:onRoundEnd(params)

end

function timeChallengeMode:finish()
	self.timerId = nil
	self.TimerText = nil
end


return timeChallengeMode