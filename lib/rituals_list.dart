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

class _RitualView extends StatefulWidget {
  final Ritual ritual;
  final bool editing;

  _RitualView({Key key, @required this.ritual, this.editing}) : super(key: key);

  @override
  _RitualViewState createState() => _RitualViewState();
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

class _RitualViewState extends State<_RitualView> {
  Widget _buildListTileTailingIcon(Ritual ritual) {
    if (widget.editing) {
      return IconButton(icon: Icon(Icons.edit), onPressed: _onLongPressed);
    }
    return FutureBuilder(
        future: ritual.isCompletedForNow(),
        builder: ((BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
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
                Icon(!snapshot.data ? Icons.keyboard_arrow_right : Icons.done,
                    color: !snapshot.data ? Colors.black54 : Colors.lightGreen,
                    size: 30.0)
              ]));
        }));
  }

  Widget buildSubTitle() {
    return FutureBuilder(
        future: widget.ritual.getComplitionStats(),
        builder:
            ((BuildContext context, AsyncSnapshot<ComplitionStats> snapshot) {
          if (!snapshot.hasData) {
            if (!snapshot.error) {
              return Text(snapshot.error.toString());
            }
            return Text("Loading...");
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
        future: widget.ritual.isCompletedForNow(),
        builder: ((BuildContext context, AsyncSnapshot<bool> snapshot) =>
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
                trailing: _buildListTileTailingIcon(widget.ritual),
                onLongPress: _onLongPressed,
                onTap: snapshot.hasData && snapshot.data ? null : _onTap)));
  }
}

class _RitualEdit extends StatefulWidget {
  RitualType type = RitualType.Evening;
  final RitualsProvider provider;

  _RitualEdit({Key key, @required this.provider}) : super(key: key);

  _RitualEditState createState() => _RitualEditState();
}

class _RitualEditState extends State<_RitualEdit> {
  TextEditingController title = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
          leading: getListTileIcon(widget.type),
          title: DropdownButton<RitualType>(
            value: widget.type,
            onChanged: (RitualType result) {
              setState(() {
                print(widget.type);
                widget.type = result;
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
          decoration: new InputDecoration.collapsed(
            hintText: "Name",
          ),
        ),
      ),
      new RaisedButton(
          onPressed: () async {
            final ritual =
                await widget.provider.createRitual(title.text, widget.type);
            Navigator.of(context, rootNavigator: true).pop(ritual.id);
          },
          child: Text("Create")),
    ]);
  }
}

class _RitualsPageState extends State<RitualsListPage> {
  final RitualsProvider provider;
  bool editing = false;
  RitualType type = RitualType.Evening;

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
              future: provider.getRituals(),
              builder: ((BuildContext context,
                  AsyncSnapshot<List<Ritual>> snapshot) {
                if (!snapshot.hasData) {
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  return Text("Loading...");
                }
                return ListView(
                  children: List.unmodifiable(snapshot.data
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
        ));
  }
}
