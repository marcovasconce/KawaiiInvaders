extends RefCounted

static var tung_god_liberado_nesta_run := false

static func desbloquear_tung_god() -> void:
	# Estado apenas em memória: trocar de cena preserva, fechar o jogo apaga.
	tung_god_liberado_nesta_run = true

static func tung_god_desbloqueado() -> bool:
	return tung_god_liberado_nesta_run
