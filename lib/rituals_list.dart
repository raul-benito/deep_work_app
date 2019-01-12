import 'package:deep_work_app/ritual_edit.dart';
import 'package:deep_work_app/ritual_stats_widget.dart';
import 'package:deep_work_app/ritual_widget.dart';
import 'package:deep_work_app/rituals_models.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RitualsListPage extends StatefulWidget {
  final RitualsProvider provider;

  RitualsListPage({Key key, @required this.provider}) : super(key: key);

  @override
  _RitualsPageState createState() => _RitualsPageState(provider: this.provider);
}

Widget getListTileIcon(RitualType type) {
  IconData iconType;
  switch (type) {
    case RitualType.Evening:
      iconType = FontAwesomeIcons.moon;
      break;
    case RitualType.Morning:
      iconType = Icons.wb_sunny;
      break;
    case RitualType.Weekly:
      iconType = Icons.event;
      break;
  }
  return Icon(iconType, color: Colors.grey);
}

class _RitualView extends StatefulWidget {
  final Ritual ritual;
  final bool editing;

  _RitualView({Key key, @required this.ritual, this.editing}) : super(key: key);

  @override
  _RitualViewState createState() => _RitualViewState();
}

class _RitualViewState extends State<_RitualView> {
  Widget _buildListTileTailingIcon(Ritual ritual, RitualState state) {
    if (widget.editing) {
      return IconButton(icon: Icon(Icons.edit), onPressed: _onLongPressed);
    }
    return Container(
        width: 78,
        child: Row(children: <Widget>[
          IconButton(
            icon: Icon(FontAwesomeIcons.chartLine,
                color: Colors.black54, size: 20.0),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RitualStatsPage(ritual: ritual),
                  ));
            },
          ),
          Icon(
              state == RitualState.Active
                  ? Icons.keyboard_arrow_right
                  : state == RitualState.Done ? Icons.done : Icons.call_missed,
              color: state != RitualState.Done
                  ? Colors.black54
                  : Colors.lightGreen,
              size: 30.0)
        ]));
  }

  Widget buildSubTitle() {
    return FutureBuilder(
        future: widget.ritual.getComplitionStats(),
        builder:
            ((BuildContext context, AsyncSnapshot<ComplitionStats> snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            return CircularProgressIndicator();
          }
          return Row(
            children: <Widget>[
              Expanded(
                  flex: 3,
                  child: Container(
                    child: LinearProgressIndicator(
                        backgroundColor: Color.fromRGBO(209, 224, 224, 0.2),
                        value: snapshot.data.ratio,
                        valueColor: AlwaysStoppedAnimation(Colors.green)),
                  )),
              Expanded(
                flex: 1,
                child: Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text(snapshot.data.description,
                        style: TextStyle(color: Colors.grey))),
              )
            ],
          );
        }));
  }

  void _onLongPressed() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RitualsEditPage(ritual: widget.ritual),
        ));
  }

  void _onTap() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RitualsPage(ritual: widget.ritual),
        ));
    Scaffold.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text("$result")));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget.ritual.getState(),
        builder: ((BuildContext context, AsyncSnapshot<RitualState> snapshot) =>
            ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                leading: Container(
                  padding: EdgeInsets.only(right: 12.0),
                  decoration: new BoxDecoration(
                      border: new Border(
                          right: new BorderSide(
                              width: 1.0, color: Colors.black12))),
                  child: getListTileIcon(widget.ritual.type),
                ),
                title: Text(
                  widget.ritual.title,
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                subtitle: buildSubTitle(),
                trailing:
                    _buildListTileTailingIcon(widget.ritual, snapshot.data),
                onLongPress: widget.editing ? null : _onLongPressed,
                onTap: widget.editing ||
                        snapshot.hasData && snapshot.data != RitualState.Active
                    ? null
                    : _onTap)));
  }
}

class _RitualEdit extends StatefulWidget {
  final RitualsProvider provider;

  _RitualEdit({Key key, @required this.provider}) : super(key: key);

  _RitualEditState createState() => _RitualEditState();
}

class _RitualEditState extends State<_RitualEdit> {
  RitualType type = RitualType.Evening;
  RitualDay day = RitualDay.Monday;
  TextEditingController title = new TextEditingController();

  Widget buildWeekdayPick() {
    return DropdownButton<RitualDay>(
        value: day,
        onChanged: (RitualDay newDay) {
          setState(() {
            day = newDay;
          });
        },
        items: RitualDay.values
            .map((RitualDay d) => DropdownMenuItem<RitualDay>(
                  value: d,
                  child: Text(d.toString().split(".")[1]),
                ))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      ListTile(
          leading: getListTileIcon(type),
          title: DropdownButton<RitualType>(
            value: type,
            onChanged: (RitualType result) {
              setState(() {
                type = result;
              });
            },
            items: <DropdownMenuItem<RitualType>>[
              const DropdownMenuItem<RitualType>(
                value: RitualType.Evening,
                child: Text('Evening'),
              ),
              const DropdownMenuItem<RitualType>(
                value: RitualType.Morning,
                child: Text('Morning'),
              ),
              const DropdownMenuItem<RitualType>(
                value: RitualType.Weekly,
                child: Text('Weekly'),
              ),
            ],
          )),
      ListTile(
        leading: const Icon(Icons.title),
        title: new TextField(
          controller: title,
          decoration: new InputDecoration(
            hintText: "Name",
          ),
        ),
      ),
      new RaisedButton(
          onPressed: () async {
            final ritual = await widget.provider.createRitual(title.text, type,
                sceduleInformation: day.index + 1);
            Navigator.of(context, rootNavigator: true).pop(ritual.id);
          },
          child: Text("Create")),
    ];

    if (type == RitualType.Weekly) {
      children.insert(
          1,
          ListTile(
            leading: Text("Every"),
            title: buildWeekdayPick(),
          ));
    }
    return Column(children: children);
  }
}

enum SelectionFilter { Current, All }

class _RitualsPageState extends State<RitualsListPage> {
  final RitualsProvider provider;
  bool editing = false;
  SelectionFilter filter = SelectionFilter.Current;

  _RitualsPageState({@required this.provider});

  void _onCreatePressed() async {
    int ritualId = await showDialog<int>(
        context: context,
        builder: (_) {
          return SimpleDialog(
              title: new Text("Adding a new Ritual"),
              children: [_RitualEdit(provider: provider)]);
        });
    final ritual = await widget.provider.getRitual(ritualId);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) =>
                RitualsEditPage(ritual: ritual)));
    setState(() {});
  }

  Widget buildSelectionTasks() {
    return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: filter.index,
        onTap: (int idx) {
          setState(() {
            filter = SelectionFilter.values[idx];
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.playlist_play), title: new Text('Current')),
          BottomNavigationBarItem(icon: Icon(Icons.toc), title: new Text('All'))
        ]);
  }

//@override
  Widget build(BuildContext context) {
    return Hero(
        tag: 'list',
        child: Scaffold(
          appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: Text("Working Rituals"),
            actions: <Widget>[
              IconButton(
                icon: Icon(editing ? Icons.save : Icons.edit),
                tooltip: 'Edit',
                onPressed: () {
                  setState(() {
                    editing = !editing;
                  });
                },
              )
            ],
          ),
          body: FutureBuilder(
              future: provider.getRituals(filter == SelectionFilter.Current),
              builder: ((BuildContext context,
                  AsyncSnapshot<List<Ritual>> snapshot) {
                if (!snapshot.hasData) {
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  return CircularProgressIndicator();
                }
                var items = snapshot.data;
                if (items.isEmpty && filter != SelectionFilter.All) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                        Image(
                          image: AssetImage('images/floating-guru-96.png'),
                          color: null,
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                        ),
                        Text("No rituals to conduct, rightnow...")
                      ]));
                }
                return ListView(
                  children: List.unmodifiable(items
                      .map((f) => _RitualView(ritual: f, editing: editing))),
                );
              })),
          floatingActionButton: editing
              ? FloatingActionButton.extended(
                  elevation: 4.0,
                  icon: const Icon(Icons.add),
                  label: const Text('Add a ritual'),
                  onPressed: _onCreatePressed,
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          bottomNavigationBar: editing ? null : buildSelectionTasks(),
        ));
  }
}
