-- @noindex

local activeProjectIndex = 0

function print(arg)
  reaper.ShowConsoleMsg(tostring(arg) .. "\n")
end

function startUndoBlock()
	reaper.Undo_BeginBlock()
end

function endUndoBlock()
	local actionDescription = "pandabot_Isolate time selection by eighth note"
	reaper.Undo_OnStateChange(actionDescription)
	reaper.Undo_EndBlock(actionDescription, -1)
end

function currentBpm()
	local timePosition = 0
	return reaper.TimeMap2_GetDividedBpmAtTime(activeProjectIndex, timePosition)
end

function lengthOfQuarterNote()
	return 60/currentBpm()
end

function lengthOfEighthNote()
	return lengthOfQuarterNote()/2
end

function lengthOfSixteenthNote()
	return lengthOfEighthNote()/2
end

function lengthOfThirtySecondNote()
	return lengthOfSixteenthNote()/2
end

function lengthOfSixtyFourthNote()
	return lengthOfThirtySecondNote()/2
end

function lengthOfHundredTwentyEighthNote()
	return lengthOfSixtyFourthNote()/2
end

--

function volumeEnvelopeIsNotVisible(trackEnvelope)

	local takeEnvelopesUseProjectTime = true
	local trackEnvelopeObject = reaper.BR_EnvAlloc(trackEnvelope, takeEnvelopesUseProjectTime)

	local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type, faderScaling = reaper.BR_EnvGetProperties(trackEnvelopeObject, true, true, true, true, 0, 0, 0, 0, 0, 0, true)
	
	local commitChanges = false
	reaper.BR_EnvFree(trackEnvelopeObject, commitChanges)
	
	return visible == false
end

function toggleTrackVolumeEnvelopeVisibility()

	local commandId = 40406
  reaper.Main_OnCommand(commandId, 0)
end

function showVolumeEnvelopes()

	local numberOfSelectedTracks = reaper.CountSelectedTracks(activeProjectIndex)

	for i = 0, numberOfSelectedTracks - 1 do

		local selectedTrack = reaper.GetSelectedTrack(activeProjectIndex, i)
		local trackEnvelope = reaper.GetTrackEnvelopeByName(selectedTrack, "Volume")

		if volumeEnvelopeIsNotVisible(trackEnvelope) then
			reaper.SetTrackSelected(selectedTrack, true)
		end
	end

	toggleTrackVolumeEnvelopeVisibility()
end

--

function startingEnvelopePointIsAtCenterValue(trackEnvelope)

	local timePosition = 0
	local envelopePointIndexAtStart = reaper.GetEnvelopePointByTime(trackEnvelope, timePosition)
	local returnValue, time, value, shape, tension, selected = reaper.GetEnvelopePoint(trackEnvelope, envelopePointIndexAtStart)
	return value == 1.0

end

function linearShape() 				return 0 end
function squareShape() 				return 1 end
function slowStartEndShape() 	return 2 end
function fastStartShape() 		return 3 end
function fastEndShape() 			return 4 end
function bezierShape() 				return 5 end

--

function addEnvelopePoints(trackEnvelope, startPosition, endPosition, noteLength)

	local selected = false
	local noSort = true
	local tension = 0.0

	local minValue = 0.0
	local centerValue = 1.0

	if startingEnvelopePointIsAtCenterValue(trackEnvelope) then
		reaper.InsertEnvelopePoint(trackEnvelope, 0.0, minValue, linearShape(), tension, selected, noSort)
	end

	reaper.InsertEnvelopePoint(trackEnvelope, startPosition-noteLength, minValue, fastEndShape(), tension, selected, noSort)
	reaper.InsertEnvelopePoint(trackEnvelope, startPosition, centerValue, linearShape(), tension, selected, noSort)

	reaper.InsertEnvelopePoint(trackEnvelope, endPosition, centerValue, fastStartShape(), tension, selected, noSort)
	reaper.InsertEnvelopePoint(trackEnvelope, endPosition+noteLength, minValue, linearShape(), tension, selected, noSort)

	reaper.Envelope_SortPoints(trackEnvelope)
end


function isolateTimeSelectionOnSelectedTracks()

	local numberOfSelectedTracks = reaper.CountSelectedTracks(activeProjectIndex)

	for i = 0, numberOfSelectedTracks - 1 do

		local selectedTrack = reaper.GetSelectedTrack(activeProjectIndex, i)
		local trackEnvelope = reaper.GetTrackEnvelopeByName(selectedTrack, "Volume")

		local isSet = false
		local isLoop = false
		local setStartingTime = 0
		local setEndingTime = 0
		local allowAutoseek = false
		local startPosition, endPosition = reaper.GetSet_LoopTimeRange2(activeProjectIndex, isSet, isLoop, setStartingTime, setEndingTime, allowAutoseek)

		local noteLength = lengthOfEighthNote()
		addEnvelopePoints(trackEnvelope, startPosition, endPosition, noteLength)
	end
end


startUndoBlock()

	showVolumeEnvelopes()
	isolateTimeSelectionOnSelectedTracks()
	reaper.UpdateArrange()

endUndoBlock()