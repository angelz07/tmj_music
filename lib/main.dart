

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TMJ-Radio Player',
      theme: ThemeData(
        primaryColor: Colors.black,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF00AFFF),
          onPrimary: const Color(0xFFFFFF00),
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFFFFF00)),
        ),
      ),
      home: const MyHomePage(),
    );
  } 
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isStreamAvailable = false;
  String url = "https://bbeamradio.ice.infomaniak.ch/bbeamradio-128.aac";
  //String url = "https://www2.cs.uic.edu/~i101/SoundFiles/CantinaBand60.wav";
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkStreamAvailability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isPlaying) {
      checkStreamAvailability();
    }
  }

  void checkStreamAvailability() async {
    bool streamActive = await isStreamActive();
    setState(() {
      isStreamAvailable = streamActive;
    });
  }

  void playPause() async {
    if (isPlaying) {
      setState(() {
        isPlaying = false;
      });
      audioPlayer.pause();
    } else {
      if (isStreamAvailable) {
        setState(() {
          isPlaying = true;
        });
        await audioPlayer.play(UrlSource(url));
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                content: const Text(
                  "Le flux n'est pas disponible. Veuillez attendre la prochaine diffusion.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFFF00),
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF00AFFF),
                    ),
                    child: const Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }

  Future<bool> isStreamActive() async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String getNextLiveMessage() {
    if (isStreamAvailable) {
      return "Live en cours!";
    }

    final now = DateTime.now();
    final brusselsTime = now.toUtc().add(const Duration(hours: 2));
    final weekday = brusselsTime.weekday;
    final hour = brusselsTime.hour;

    DateTime nextLive;
    if (weekday == DateTime.monday || (weekday == DateTime.tuesday && hour >= 20)) {
      nextLive = DateTime(brusselsTime.year, brusselsTime.month, brusselsTime.day + (DateTime.thursday - weekday), 17);
    } else if (weekday == DateTime.wednesday || (weekday == DateTime.thursday && hour >= 20)) {
      nextLive = DateTime(brusselsTime.year, brusselsTime.month, brusselsTime.day + (DateTime.tuesday - weekday), 17);
    } else {
      nextLive = DateTime(brusselsTime.year, brusselsTime.month, brusselsTime.day + ((DateTime.tuesday - weekday) % 7), 17);
    }

    final dayFormat = DateFormat('EEEE d MMMM y', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    return "Prochain live le ${dayFormat.format(nextLive)} à ${timeFormat.format(nextLive)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TMJ-Radio Player"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100.0,
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Bienvenue sur TMJ-Radio !',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Color(0xFFFFFF00),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: const Color(0xFF00AFFF), width: 2),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      getNextLiveMessage(),
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 64.0,
                    color: const Color(0xFF00AFFF),
                    onPressed: playPause,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.facebook),
                  color: const Color(0xFF00AFFF),
                  iconSize: 40.0,
                  onPressed: _launchFacebook,
                ),
                const SizedBox(width: 20.0),
                IconButton(
                  icon: const Icon(Icons.public),
                  color: const Color(0xFF00AFFF),
                  iconSize: 40.0,
                  onPressed: _launchWebsite,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // Ouvre dans le navigateur par défaut
      );
    } else {
      throw 'Could not launch $urlString';
    }
  }

  void _launchFacebook() async {
    final Uri facebookAppUrl = Uri.parse("fb://profile/61558322909738");
    final Uri facebookWebUrl = Uri.parse("https://www.facebook.com/profile.php?id=61558322909738");

    if (await canLaunchUrl(facebookAppUrl)) {
      await launchUrl(facebookAppUrl, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(facebookWebUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _launchWebsite() async {
    final Uri websiteUrl = Uri.parse("https://www.tmj-music.be/");
    
    if (await canLaunchUrl(websiteUrl)) {
      await launchUrl(websiteUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $websiteUrl';
    }
  }


}
