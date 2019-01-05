import 'package:deep_work_app/rituals_models.dart';
import 'package:flutter/material.dart';

class RitualsEditPage extends StatefulWidget {
  final Ritual ritual;

  RitualsEditPage({Key key, @required this.ritual}) : super(key: key);

  @override
  _RitualsEditPageState createState() => _RitualsEditPageState();
}

class _RitualsEditPageState extends State<RitualsEditPage> {
  List<RitualStep> _steps;

  Widget body() {
    return FutureBuilder(
        future: widget.ritual.getRitualSteps(),
        builder:
            (BuildContext context, AsyncSnapshot<List<RitualStep>> snapshot) {
          if (!snapshot.hasData) {
            return Text("Loading...");
          }
          _steps = snapshot.data;
          return ReorderableListView(
              children: snapshot.data
                  .map((f) => ListTile(
                      key: ValueKey(f),
                      title: Text(f.title),
                      subtitle: Text(f.description)))
                  .toList(),
              onReorder: (int oldIndex, int newIndex) async {
                if (oldIndex < newIndex) {
                  // removing the item at oldIndex will shorten the list by 1.
                  newIndex -= 1;
                }
                final RitualStep element = _steps.removeAt(oldIndex);
                _steps.insert(newIndex, element);
                await widget.ritual.updateRitualStepOrder(_steps);
                setState(() {});
              });
        });
  }

  Widget floatingButton() {
    TextEditingController title = new TextEditingController();
    TextEditingController description = new TextEditingController();
    return FloatingActionButton(
      onPressed: () async {
        final message = await showDialog<String>(
            context: context,
            builder: (_) {
              return SimpleDialog(title: new Text("Adding a Step"), children: [
                new Column(children: [
                  new ListTile(
                    leading: const Icon(Icons.title),
                    title: new TextField(
                      controller: title,
                      decoration: new InputDecoration.collapsed(
                        hintText: "Title",
                      ),
                    ),
                  ),
                  new ListTile(
                      leading: const Icon(Icons.description),
                      title: new TextField(
                        controller: description,
                        decoration: new InputDecoration(
                          hintText: "Description",
                        ),
                      )),
                  new RaisedButton(
                      onPressed: () {
                        widget.ritual.insertStep(title.text, description.text);
                        Navigator.pop(context, "Created");
                      },
                      child: Text("Create")),
                ])
              ]);
            });
        if (message.isNotEmpty) {
          setState(() {});
        }
      },
      child: Icon(Icons.add),
    );
  }

  //@override
  Widget build(BuildContext context) {
    return Hero(
        tag: 'ritual',
        child: Scaffold(
            appBar: AppBar(
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: Text("Ritual " + widget.ritual.title),
            ),
            floatingActionButton: floatingButton(),
            body: body()));
  }
}
