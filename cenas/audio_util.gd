extends RefCounted

static func tocar(no_pai: Node, fluxo: AudioStream, loop := false, volume_db := 0.0) -> AudioStreamPlayer:
	if not is_instance_valid(no_pai) or not fluxo:
		return null
	var player := AudioStreamPlayer.new()
	var copia := fluxo.duplicate() as AudioStream
	if copia is AudioStreamMP3:
		copia.loop = loop
	elif copia is AudioStreamWAV:
		copia.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	player.stream = copia
	player.volume_db = volume_db
	player.max_polyphony = 8
	no_pai.add_child(player)
	player.play()
	if not loop:
		player.finished.connect(player.queue_free)
	return player
