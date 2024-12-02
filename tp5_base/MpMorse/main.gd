extends Node2D

# réseau
var peer = ENetMultiplayerPeer.new()
var hostname = "localhost"
var port = 11234

# état du jeu
var host_text = ""
var host_morse = ""
var client_answer = []
var game_over = false

# Load the sound files
var dot_sound = preload("res://dot.wav")
var boop_sound = preload("res://boop.wav")

# ===== GAME LOOP =====
func _physics_process(_delta):
	if (Input.is_action_just_pressed("ui_dot")): # fléche UP, point
		rpc("_play_dot_on_server")
		pass
	elif (Input.is_action_just_pressed("ui_dash")): # fléche DOWN, trait d'union
		rpc("_play_dash_on_server")
		pass

# ===== EVÉNEMENTS INTERFACE =====
func _on_host_pressed():
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	
	# montrer l'interface host
	$SendText.show()
	$MainMenu.hide()
	
func _on_join_pressed():
	peer.create_client(hostname, port)
	multiplayer.multiplayer_peer = peer
	
	# montrer l'interface client
	$ReceiveText.show()
	$MainMenu.hide()
	
func _on_btn_send_pressed():
	# à chaque fois que J1 envoye une message, le jeu est redémarré
	client_answer = []
	game_over = false
	host_text = $SendText/TextEdit.get_text()
	
	# chiffrer la message comme réference
	host_morse = get_morse_from_string(host_text)
	$SendText/AnswerPreview.set_text(host_morse)
	
	# envoyer la message à J2
	rpc("_show_text_on_client", host_text)
# ===== LOGIQUE DU JEU =====
func get_morse_from_string(text: String) -> String:
	var morse_code = {
		'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.', 'G': '--.', 'H': '....',
		'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..', 'M': '--', 'N': '-.', 'O': '---', 'P': '.--.',
		'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
		'Y': '-.--', 'Z': '--..', '1': '.----', '2': '..---', '3': '...--', '4': '....-', '5': '.....',
		'6': '-....', '7': '--...', '8': '---..', '9': '----.', '0': '-----', ' ': '/'
	}
	
	var morse_text = []
	
	for aChar in text.to_upper():
		if aChar in morse_code:
			morse_text.append(morse_code[aChar])
	
	return "".join(morse_text)

func is_answer_equal() -> bool:
	var client_answer_str = ""
	for char in client_answer:
		client_answer_str += char
	return host_morse == client_answer_str

func check_victory():
	
	if is_answer_equal():
		game_over = true
		rpc("_send_success_au_client")
	else:
		client_answer.clear()
		rpc("_send_failure_au_client")

# ===== MÉTHODES RPC =====
@rpc("authority", "call_remote", "reliable")
func _show_text_on_client(text):
	print("Envoyé à J2: ", text)
	$ReceiveText/TextDisplay.text = text
	
@rpc("any_peer", "call_remote", "reliable")
func _play_dot_on_server():
	if not game_over:
		print("Envoyé à J1")
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = dot_sound
		add_child(audio_player)
		audio_player.play() 
		client_answer.append(".")
		
	if client_answer.size() == host_morse.length():
		check_victory()

@rpc("any_peer", "call_remote", "reliable")
func _play_dash_on_server():
	if not game_over:
		print("Envoyé à J1")
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = boop_sound
		add_child(audio_player)
		audio_player.play()
		client_answer.append("-")
		
	if client_answer.size() == host_morse.length():
		check_victory()

@rpc("any_peer", "call_remote", "reliable")
func _send_success_au_client():
	print("got Success du vot' Host")
	$ReceiveText/hostMessage.text = "You are Success"
	
@rpc("any_peer", "call_remote", "reliable")
func _send_failure_au_client():
	print("got Failure d'votre Host")
	$ReceiveText/hostMessage.text = "Failure désolé :((, recommence"
