import 'package:deep_work_app/generic_widgets.dart';
import 'package:deep_work_app/ritual_widget.dart';
import 'package:deep_work_app/rituals_list.dart';
import 'package:deep_work_app/rituals_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Working Rituals',
      theme: getTheme(),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  AppNotificationProvider _notificationProvider;
  RitualsProvider _provider;
  BuildContext context;

  Future onSelectNotification(String payload) async {
    Ritual ritual = await _provider.getRitual(int.parse(payload));
    await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => RitualsPage(ritual: ritual)),
    );
  }

  MyHomePage({Key key}) : super(key: key) {
    _notificationProvider = AppNotificationProvider(onSelectNotification);
    _provider = RitualsProvider("rituals_v1.db", _notificationProvider);
  }

  //@override
  Widget build(BuildContext context) {
    this.context = context;
    return RitualsListPage(provider: _provider);
  }
}

class AppNotificationProvider extends NotificationProvider {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  AppNotificationProvider(SelectNotificationCallback callback) {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: callback);
  }

  @override
  void armNotification(Future<Ritual> ritualFuture) async {
    var ritual = await ritualFuture;
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'work_rituals id',
        'Work rituals notifications',
        'Notifications used to remind you of your active rituals.');
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    var time;
    switch (ritual.type) {
      case RitualType.Evening:
        time = Time(19, 30, 0);
        break;

      case RitualType.Morning:
        time = Time(8, 0, 0);
        break;

      case RitualType.Weekly:
        Day day = List.of(Day.values).firstWhere(
            (day) => day.value == ((ritual.scheduleInformation + 1) % 7 + 1));
        return flutterLocalNotificationsPlugin.showWeeklyAtDayAndTime(
            ritual.id,
            'Remember to take your ritual ' + ritual.title,
            '',
            day,
            Time(8, 0, 0),
            platformChannelSpecifics,
            payload: ritual.id.toString());
    }

    await flutterLocalNotificationsPlugin.showDailyAtTime(
        ritual.id,
        'Remember to take your ritual ' + ritual.title,
        '',
        time,
        platformChannelSpecifics,
        payload: ritual.id.toString());
  }
}
