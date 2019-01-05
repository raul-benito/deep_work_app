import 'package:deep_work_app/ritual_edit.dart';
import 'package:deep_work_app/ritual_stats_widget.dart';
import 'package:deep_work_app/ritual_widget.dart';
import 'package:deep_work_app/rituals_models.dart';
import 'package:flutter/material.dart';

class RitualsListPage extends StatefulWidget {
  final RitualsProvider provider;

  RitualsListPage({Key key, @required this.provider}) : super(key: key);

  @override
  _RitualsPageState createState() => _RitualsPageState(provider: this.provider);
}

class _RitualsPageState extends State<RitualsListPage> {
  final RitualsProvider provider;
  List<Ritual> _rituals = new List<Ritual>();

  _RitualsPageState({@required this.provider});

  Widget buildListTile(Ritual ritual) {
    final endIcon = FutureBuilder(
        future: ritual.isCompletedForNow(),
        builder: ((BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          return Container(
              width: 78,
              child: Row(children: <Widget>[
                IconButton(
                  icon:
                      Icon(Icons.data_usage, color: Colors.black54, size: 20.0),
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

    return FutureBuilder(
        future: ritual.isCompletedForNow(),
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
                  child: Icon(Icons.event, color: Colors.grey),
                ),
                title: Text(
                  ritual.title,
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                subtitle: FutureBuilder(
                    future: ritual.getComplitionStats(),
                    builder: ((BuildContext context,
                        AsyncSnapshot<ComplitionStats> snapshot) {
                      if (!snapshot.hasData) {
                        return Text("Loading...");
                      }
                      return Row(
                        children: <Widget>[
                          Expanded(
                              flex: 3,
                              child: Container(
                                child: LinearProgressIndicator(
                                    backgroundColor:
                                        Color.fromRGBO(209, 224, 224, 0.2),
                                    value: snapshot.data.ratio,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.green)),
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
                    })),
                trailing: endIcon,
                onLongPress: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RitualsEditPage(ritual: ritual),
                      ));
                },
                onTap: snapshot.hasData && snapshot.data
                    ? null
                    : () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RitualsPage(ritual: ritual),
                            ));
                        Scaffold.of(context)
                          ..removeCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text("$result")));
                        setState(() {});
                      })));
  }

  @override
  void initState() {
    super.initState();
    provider.getRituals().then((value) {
      setState(() {
        _rituals = value;
      });
    });
  }

//@override
  Widget build(BuildContext context) {
    TextEditingController title = new TextEditingController();
    return Hero(
        tag: 'list',
        child: Scaffold(
            appBar: AppBar(
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: Text("Working Rituals"),
            ),
            body: ListView(
              children:
                  List.unmodifiable(_rituals.map((f) => buildListTile(f))),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final message = await showDialog<String>(
                    context: context,
                    builder: (_) {
                      return SimpleDialog(
                          title: new Text("Adding a new Ritual"),
                          children: [
                            new Column(children: [
                              new ListTile(
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
                                    final ritual = await widget.provider
                                        .createRitual(title.text);
                                    final message =
                                        await Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder:
                                                    (BuildContext context) =>
                                                        RitualsEditPage(
                                                            ritual: ritual)));
                                    return message;
                                  },
                                  child: Text("Create")),
                            ])
                          ]);
                    });
                if (message.isNotEmpty) {
                  setState(() {});
                }
              },
              child: Icon(Icons.edit),
            )));
  }
}
