local freeChallengeMode={key="freeChallengeMode"}

function freeChallengeMode:new(options) 
	o = options or {}
	setmetatable(o, self)
    self.__index = self
	return o
end

function freeChallengeMode:onStageBegin(textField)
	textField.text = "No Limit"
end

return freeChallengeMode