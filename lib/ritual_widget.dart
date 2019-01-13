import 'package:deep_work_app/generic_widgets.dart';
import 'package:deep_work_app/rituals_models.dart';
import 'package:flutter/material.dart';

class StepView {
  final RitualStep _step;
  StepState _icon = StepState.indexed;

  StepView(RitualStep step) : _step = step;

  void markDone() {
    _icon = StepState.complete;
  }

  Step toStep() {
    return Step(
        title: Text(_step.title),
        content: Text(""),
        state: _icon,
        subtitle: Text(_step.description));
  }
}

class RitualsPage extends StatefulWidget {
  final Ritual ritual;

  RitualsPage({Key key, @required this.ritual}) : super(key: key);

  @override
  _RitualsPageState createState() => _RitualsPageState();
}

class _RitualsPageState extends State<RitualsPage> {
  int _step = 0;
  List<StepView> _steps = new List<StepView>();

  void _incrementCounter(BuildContext context) {
    setState(() {
      _steps[_step].markDone();
      if (_step + 1 == _steps.length) {
        widget.ritual.markCompletion();
        Navigator.pop(context, 'Done');
        return;
      }
      _step++;
    });
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
              elevation: getDefaultElevation(),
            ),
            body: FutureBuilder(
                future: widget.ritual.getRitualSteps(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<RitualStep>> snapshot) {
                  if (!snapshot.hasData) {
                    return Text("Loading...");
                  }
                  _steps =
                      List.unmodifiable(snapshot.data.map((f) => StepView(f)));
                  return Stepper(
                    steps: this._steps.map((f) => f.toStep()).toList(),
                    currentStep: this._step,
                    onStepContinue: () => this._incrementCounter(context),
                  );
                })));
  }
}
