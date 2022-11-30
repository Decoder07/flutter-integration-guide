import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: ElevatedButton(
          style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ))),
          onPressed: () => {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const MeetingPage()))
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Text(
              'Join',
            ),
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage>
    implements HMSUpdateListener {
  late HMSSDK hmsSDK;
  String userName = "test_user";
  String authToken =
      "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhY2Nlc3Nfa2V5IjoiNjE4YjU1OTBiZTZjM2MwYjM1MTUwYWJhIiwicm9vbV9pZCI6IjYxOGI1NWQ4YmU2YzNjMGIzNTE1MGFiZCIsInVzZXJfaWQiOiIwNmQ4ZGNlYS0zYzRmLTQyZmEtOTUzOC03NTY3YTk1ZDQ1YzEiLCJyb2xlIjoiaG9zdCIsImp0aSI6IjU1ZmM4NDJhLWM3YWMtNGJlYS1iNmQyLTJlNjgxN2NkZTNjNSIsInR5cGUiOiJhcHAiLCJ2ZXJzaW9uIjoyLCJleHAiOjE2Njk4OTMyNzF9.WwlPANjQf9S6XObpFXtMlD5nFCefTDCRL4sF7p-FWQI"; //To Do
  Offset position = const Offset(5, 5);
  bool isJoinSuccessful = false;
  HMSPeer? localPeer, remotePeer;
  HMSVideoTrack? localPeerVideoTrack, remotePeerVideoTrack;
  @override
  void initState() {
    super.initState();
    hmsSDK = HMSSDK();
    hmsSDK.build();
    hmsSDK.addUpdateListener(listener: this);
    hmsSDK.join(config: HMSConfig(authToken: authToken, userName: userName));
  }

  @override
  void onJoin({required HMSRoom room}) {
    // TODO: implement onJoin
    room.peers?.forEach((peer) {
      if (peer.isLocal) {
        localPeer = peer;
        if (peer.videoTrack != null) {
          localPeerVideoTrack = peer.videoTrack;
        }
      }
    });
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    if (update == HMSPeerUpdate.peerJoined) {
      if (!peer.isLocal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            remotePeer = peer;
          });
        });
      }
    } else if (update == HMSPeerUpdate.peerLeft) {
      if (!peer.isLocal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            remotePeer = null;
          });
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            localPeer = null;
          });
        });
      }
    }
  }

  @override
  void onTrackUpdate(
      {required HMSTrack track,
      required HMSTrackUpdate trackUpdate,
      required HMSPeer peer}) {
    if (track.kind == HMSTrackKind.kHMSTrackKindVideo) {
      if (trackUpdate == HMSTrackUpdate.trackRemoved) {
        if (peer.isLocal) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              localPeerVideoTrack = null;
            });
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              remotePeerVideoTrack = null;
            });
          });
        }
        return;
      }
      if (peer.isLocal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            localPeerVideoTrack = track as HMSVideoTrack;
          });
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            remotePeerVideoTrack = track as HMSVideoTrack;
          });
        });
      }
    }
  }

  @override
  void onAudioDeviceChanged(
      {HMSAudioDevice? currentAudioDevice,
      List<HMSAudioDevice>? availableAudioDevice}) {
    // TODO: implement onAudioDeviceChanged
  }

  @override
  void onChangeTrackStateRequest(
      {required HMSTrackChangeRequest hmsTrackChangeRequest}) {
    // TODO: implement onChangeTrackStateRequest
  }

  @override
  void onHMSError({required HMSException error}) {
    // TODO: implement onHMSError
  }

  @override
  void onMessage({required HMSMessage message}) {
    // TODO: implement onMessage
  }

  @override
  void onReconnected() {
    // TODO: implement onReconnected
  }

  @override
  void onReconnecting() {
    // TODO: implement onReconnecting
  }

  @override
  void onRemovedFromRoom(
      {required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer}) {
    // TODO: implement onRemovedFromRoom
  }

  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {
    // TODO: implement onRoleChangeRequest
  }

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {
    // TODO: implement onRoomUpdate
  }

  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {
    // TODO: implement onUpdateSpeakers
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // context.read<HMSNotifier>().leaveRoom();
        Navigator.pop(context);
        return true;
      },
      child: SafeArea(
          child: Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(children: [
            (remotePeer == null)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: Container(
                        color: Colors.black.withOpacity(0.9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            CircleAvatar(
                              radius: 30,
                              child: Text(
                                "D",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Text(
                              "Connecting...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : remotePeerVideoTrack?.isMute ?? true
                    ? Center(
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration:
                              BoxDecoration(shape: BoxShape.circle, boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withAlpha(60),
                              blurRadius: 10.0,
                              spreadRadius: 2.0,
                            ),
                          ]),
                        ),
                      )
                    : (remotePeerVideoTrack != null)
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            child: HMSVideoView(
                                scaleType: ScaleType.SCALE_ASPECT_FILL,
                                track: remotePeerVideoTrack!,
                                matchParent: false),
                          )
                        : const Center(child: Text("No Video")),
            remotePeerVideoTrack?.isMute ?? true
                ? Align(
                    alignment: Alignment.center,
                    child: Text(
                      remotePeer?.name.substring(0, 1) ?? "D",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  )
                : Container(),
            localPeerVideoTrack?.isMute ?? true
                ? Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(60),
                          blurRadius: 10.0,
                          spreadRadius: 2.0,
                        ),
                      ]),
                    ),
                  )
                : (localPeerVideoTrack != null)
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: HMSVideoView(
                            scaleType: ScaleType.SCALE_ASPECT_FILL,
                            track: remotePeerVideoTrack!,
                            matchParent: false),
                      )
                    : const Center(child: Text("No Video")),
            localPeerVideoTrack?.isMute ?? true
                ? Align(
                    alignment: Alignment.center,
                    child: Text(
                      remotePeer?.name.substring(0, 1) ?? "D",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  )
                : Container(),
            Positioned(
              top: 10,
              left: 10,
              child: GestureDetector(
                onTap: () {
                  hmsSDK.leave();
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        hmsSDK.leave();
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration:
                            BoxDecoration(shape: BoxShape.circle, boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(60),
                            blurRadius: 3.0,
                            spreadRadius: 5.0,
                          ),
                        ]),
                        child: const CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.call_end, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  Widget localPeerTile(
      HMSVideoTrack? localTrack, HMSPeer? peer, BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: Container(
        height: 150,
        width: 120,
        color: Colors.grey.withOpacity(0.1),
        child: (localTrack != null && !(localTrack.isMute))
            ? HMSVideoView(
                track: localTrack,
              )
            : Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(4),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.blue,
                        blurRadius: 20.0,
                        spreadRadius: 5.0,
                      ),
                    ],
                  ),
                  child: Text(
                    peer?.name.substring(0, 1) ?? "D",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
      ),
    );
  }
}
