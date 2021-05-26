
DogProduction = function()
	if Kennel.IsDead then
		return
	end

	ussr.Build({"dog"}, function(unit)
		Trigger.AfterDelay(DateTime.Seconds(1), DogProduction)

		Utils.Do(unit, function(u)
			u.AttackMove(BaseCameraPoint.Location)
			Trigger.OnIdle(u, u.Hunt)
		end)
	end)
end

WorldLoaded = function()

	player = Player.GetPlayer("Greece")
	ussr = Player.GetPlayer("USSR")

	TanyaSurviveObjective = player.AddPrimaryObjective("Tanya must survive.")
	Trigger.OnKilled(tanya, function()
		Media.PlaySpeechNotification(player, "ObjectiveNotMet")
		player.MarkFailedObjective(TanyaSurviveObjective)
	end)

	DestroyTheKennelObjective = player.AddPrimaryObjective("Destroy the kennel")
	Trigger.OnKilled(Kennel, function()
		if not player.IsObjectiveFailed(TanyaSurviveObjective) then
			player.MarkCompletedObjective(TanyaSurviveObjective)
		end
		player.MarkCompletedObjective(DestroyTheKennelObjective)
	end)
	
	Trigger.AfterDelay(DateTime.Seconds(3), DogProduction)

	Camera.Position = BaseCameraPoint.CenterPosition
end
