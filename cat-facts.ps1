#Run this every 1/2 hour and in an 8 hour work day there will be approximately 3 times per day that your victim hears a cat fact
#if ((Get-Random -Maximum 10000) -lt 1875) {
	[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
	Add-Type -AssemblyName System.Speech
	$catFact = $(Invoke-RestMethod 'https://catfact.ninja/fact' -UseBasicParsing).fact
	$(New-object "System.Speech.Synthesis.SpeechSynthesizer").Speak("Did. You. Know? $catFact")
#}