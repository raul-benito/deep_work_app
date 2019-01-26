import 'dart:math';

import 'package:deep_work_app/generic_widgets.dart';
import 'package:deep_work_app/rituals_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:flutter_calendar_carousel/classes/event_list.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart'
    show CalendarCarousel;

class RitualStatsPage extends StatefulWidget {
  final Ritual ritual;

  RitualStatsPage({Key key, @required this.ritual}) : super(key: key);

  @override
  _RitualStatsPageState createState() {
    return _RitualStatsPageState();
  }
}

class _RitualStatsPageState extends State<RitualStatsPage> {
  //@override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: getDefaultElevation(),
          title: Text("Stats for " + this.widget.ritual.title),
        ),
        body: create());
  }

  static createEvent(DateTime date) {
    return Event(
        date: date,
        icon: new Container(
            decoration: new BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.all(Radius.circular(1000)),
                border: Border.all(color: Colors.lightBlueAccent, width: 2.0)),
            child: new Center(child: new Text(date.day.toString()))));
  }

  static fillEvents(EventList events, List<DateTime> dates) {
    dates.forEach((date) {
      final clean = DateTime(date.year, date.month, date.day);
      if (events.getEvents(clean).isEmpty) {
        events.add(clean, createEvent(clean));
      }
    });
  }

  Widget create() {
    return FutureBuilder(
        future: this.widget.ritual.getCompletions(DateTime.now()),
        builder:
            (BuildContext context, AsyncSnapshot<List<DateTime>> snapshot) {
          EventList events = EventList();
          if (!snapshot.hasData) {
            return Text("loading");
          }
          fillEvents(events, snapshot.data);
          return Container(
              child: Center(
                  child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                CalendarCarousel(
                  weekendTextStyle: TextStyle(
                    color: Colors.red,
                  ),
                  onCalendarChanged: (dc) async {
                    final dates = await this.widget.ritual.getCompletions(dc);
                    fillEvents(events, dates);
                  },
                  weekFormat: false,
                  height: constraints.maxHeight,
                  width: min(constraints.maxHeight, constraints.maxWidth),
                  daysHaveCircularBorder: true,
                  markedDatesMap: events,
                  markedDateShowIcon: true,
                ),
          )));
        });
  }
}
