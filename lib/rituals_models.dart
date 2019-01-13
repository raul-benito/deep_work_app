import 'dart:async';

import 'package:sqflite/sqflite.dart';

abstract class NotificationProvider {
  void armNotification(Future<Ritual> ritual);
}

/// Instance of a ritual completion.
class RitualCompletion {
  int id;
  int ritualId;
  DateTime completionTime;

  static final String table = "ritualsComplete";
  static final String columnId = "_id";
  static final String columnRitual = "ritualId";
  static final String columnDone = "timeStamp";

  static String getTableCreation() {
    return '''create table $table (
       $columnId integer primary key autoincrement, 
       $columnRitual integer not null,
       $columnDone integer DEFAULT CURRENT_TIMESTAMP,
       FOREIGN KEY($columnRitual) REFERENCES rituals(_id))
    ''';
  }

  static Future<RitualCompletion> insert(int ritualId, Database db) async {
    final id = await db.insert(table, {columnRitual: ritualId});
    return get(id, db);
  }

  static RitualCompletion _fromMap(Map map) {
    RitualCompletion ritualComplete = new RitualCompletion();
    ritualComplete.completionTime = DateTime.parse(map[columnDone]);
    ritualComplete.id = map[columnId];
    ritualComplete.ritualId = map[columnRitual];
    return ritualComplete;
  }

  static Future<RitualCompletion> get(int completionId, Database db) async {
    Map map = await _getById(completionId, db);
    if (map == null) {
      return Future.error("No completion by that id.");
    }
    return _fromMap(map);
  }

  static Future<List<RitualCompletion>> getByDateRangeAndRitualId(
      int ritualId, DateTime from, DateTime to, Database db) async {
    final results = List<RitualCompletion>();
    List<Map> maps = await db.query(table,
        columns: [columnId, columnDone, columnRitual],
        where:
            '$columnRitual = ? and $columnDone BETWEEN date(?) AND date(?,+"1 day")',
        whereArgs: [ritualId, from.toIso8601String(), to.toIso8601String()]);
    maps.forEach((map) {
      results.add(_fromMap(map));
    });
    return results;
  }

  static Future<CompletionStats> getLongestSteak(
      int ritualId, Database db) async {
    final filterBySingleDate =
        "(select distinct(date($columnDone)) as $columnDone from $table where $columnRitual=$ritualId)";
    List<Map<String, dynamic>> maps = await db.rawQuery("""
        select max(date($columnDone)) as $columnDone, count(*) as streak
        from (select t1.$columnDone as $columnDone ,
              date(t1.$columnDone,
                   -(select count(*) from $filterBySingleDate 
                     t2 where date(t2.$columnDone)<=date(t1.$columnDone)) ||' day') as grp
    from $filterBySingleDate t1 ) group by grp order by streak DESC""");
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Map todayValue;
    try {
      todayValue =
          maps.singleWhere((f) => DateTime.parse(f[columnDone]) == today);
    } catch (e) {
      final yesterday = today.subtract(Duration(days: 1));
      todayValue = maps.singleWhere(
          (f) => DateTime.parse(f[columnDone]) == yesterday,
          orElse: () => {"streak": 0});
    }
    return CompletionStats()
      ..ritualId = ritualId
      ..maxStride = maps.isEmpty ? 0 : maps.first["streak"]
      ..currentStride = todayValue["streak"];
  }

  // Private parts.
  static Future<Map> _getById(int id, Database db) async {
    List<Map> maps = await db.query(table,
        columns: [columnId, columnDone, columnRitual],
        where: "$columnId = ?",
        whereArgs: [id]);
    if (maps.length > 0) {
      return maps.first;
    }
    return null;
  }
}

class RitualStep {
  int id;
  int ritualId;
  String title;
  String description;

  static final String table = "ritualSteps";
  static final String columnId = "_id";
  static final String columnRitualId = "ritualId";
  static final String columnTitle = "title";
  static final String columnDescription = "description";
  static final String columnOrder = "stepOrder";

  static String getTableCreation() {
    return '''create table $table (
       $columnId integer primary key autoincrement, 
       $columnRitualId integer,
       $columnTitle string,
       $columnDescription string,
       $columnOrder integer,
       FOREIGN KEY($columnRitualId) REFERENCES rituals(_id))      
    ''';
  }

  static Future<RitualStep> insert(
      String title, String description, int ritualId, Database db) async {
    RitualStep step = new RitualStep();
    final result = await db.query(table,
        columns: ["MAX($columnOrder)"],
        where: "$columnRitualId = ?",
        whereArgs: [ritualId]);
    var order = 1;
    if (result.first["MAX($columnOrder)"] != null) {
      order = result.first["MAX($columnOrder)"] + 1;
    }
    step.id = await db.insert(table, {
      columnTitle: title,
      columnDescription: description,
      columnRitualId: ritualId,
      columnOrder: order,
    });
    return get(step.id, db);
  }

  Future updateOrder(int newOrder, Database db) async {
    return db.update(table, {columnOrder: newOrder},
        where: "$columnId = ?", whereArgs: [id]);
  }

  static Future<RitualStep> get(int stepId, Database db) async {
    Map map = await _getById(stepId, db);
    if (map != null) {
      return fromMap(map);
    }
    return Future.error("No step by that id.");
  }

  static RitualStep fromMap(Map map) {
    RitualStep step = new RitualStep();
    step.id = map[columnId];
    step.title = map[columnTitle].toString();
    step.description = map[columnDescription].toString();
    step.ritualId = map[columnRitualId];
    return step;
  }

  static Future<List<RitualStep>> getByRitualId(
      int ritualId, Database db) async {
    List<RitualStep> result = new List<RitualStep>();
    var maps = await db.query(table,
        columns: [
          columnId,
          columnTitle,
          columnDescription,
          columnRitualId,
          columnOrder
        ],
        where: "$columnRitualId = ?",
        whereArgs: [ritualId],
        orderBy: columnOrder);
    maps.forEach((map) {
      result.add(fromMap(map));
    });
    return result;
  }

  // Private parts.
  static Future<Map> _getById(int id, Database db) async {
    List<Map> maps = await db.query(table,
        columns: [columnId, columnTitle, columnDescription, columnRitualId],
        where: "$columnId = ?",
        whereArgs: [id]);
    if (maps.length > 0) {
      return maps.first;
    }
    return null;
  }
}

class CompletionStats {
  int ritualId;
  double ratio = 0;
  int maxStride = 0;
  int currentStride = 0;
  String description;
}

enum RitualType { Morning, Evening, Weekly }
enum RitualDay {
  Monday,
  Tuesday,
  Wednesday,
  Thursday,
  Friday,
  Saturday,
  Sunday
}
enum RitualState { Done, Skip, Active }

class Ritual {
  int id;
  String title;
  DateTime creationTime;
  int scheduleInformation;
  RitualType type;
  Future<RitualState> state;

  Database _db;

  Future<RitualStep> insertStep(String title, String description) {
    return RitualStep.insert(title, description, id, _db);
  }

  static final String table = "rituals";
  static final String columnId = "_id";
  static final String columnTitle = "description";
  static final String columnCreation = "timeStamp";
  static final String columnType = "ritualType";
  static final String columnScheduleInformation = "scheduleInformation";
  static final List<String> columns = [
    columnId,
    columnTitle,
    columnCreation,
    columnType,
    columnScheduleInformation
  ];

  static String getTableCreation() {
    return '''create table $table (
       $columnId integer primary key autoincrement, 
       $columnTitle string,
       $columnType integer,
       $columnScheduleInformation integer,
       $columnCreation integer DEFAULT CURRENT_TIMESTAMP)
    ''';
  }

  static Future<Ritual> insert(String title, RitualType type, Database db,
      {int scheduleInformation}) async {
    final id = await db.insert(table, {
      columnTitle: title,
      columnType: type.index,
      columnScheduleInformation: scheduleInformation
    });
    return get(id, db);
  }

  static Future<List<Ritual>> getRituals(Database db) async {
    List<Map> maps = await db.query(table, columns: columns);
    return maps.map((map) => fromMap(db, map)).toList();
  }

  static Future<Ritual> get(int ritualId, Database db) async {
    Map map = await _getById(ritualId, db);
    if (map != null) {
      return fromMap(db, map);
    }
    return Future.error("No ritual by that id.");
  }

  static Ritual fromMap(Database db, Map map) {
    Ritual ritual = new Ritual();
    ritual._db = db;
    ritual.creationTime = DateTime.parse(map[columnCreation]);
    ritual.id = map[columnId];
    ritual.title = map[columnTitle].toString();
    ritual.type = RitualType.values[map[columnType]];
    ritual.scheduleInformation = map[columnScheduleInformation];
    return ritual;
  }

  // Private parts.
  static Future<Map> _getById(int id, Database db) async {
    List<Map> maps = await db.query(table,
        columns: columns, where: "$columnId = ?", whereArgs: [id]);
    if (maps.length > 0) {
      return maps.first;
    }
    return null;
  }

  Future<List<RitualStep>> getRitualSteps() async {
    return RitualStep.getByRitualId(id, _db);
  }

  Future updateRitualStepOrder(List<RitualStep> newOrder) async {
    int i = 0;
    newOrder.forEach((f) async => await f.updateOrder(i++, _db));
  }

  Future<List<DateTime>> getCompletions(DateTime around) async {
    final instances = await RitualCompletion.getByDateRangeAndRitualId(
        id, around.subtract(Duration(days: 32)), around, _db);
    return instances.map((f) => f.completionTime).toList();
  }

  void markCompletion() {
    RitualCompletion.insert(id, _db);
  }

  Future<CompletionStats> getCompletionStats() async {
    final stats = await RitualCompletion.getLongestSteak(id, _db);
    if (stats.maxStride < 40) stats.maxStride = 40;
    stats.description = "${stats.currentStride} / ${stats.maxStride}";
    stats.ratio = stats.currentStride / stats.maxStride;
    return stats;
  }

  Future<RitualState> getState() async {
    if (state == null) {
      state = _getState();
    }
    return state;
  }

  Future<RitualState> _getState() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completion =
        await RitualCompletion.getByDateRangeAndRitualId(id, today, now, _db);
    switch (type) {
      case RitualType.Morning:
        if (completion.isNotEmpty) return RitualState.Done;
        if (now.hour > 12) return RitualState.Skip;
        return RitualState.Active;

      case RitualType.Evening:
        if (completion.isNotEmpty) return RitualState.Done;
        if (now.hour > 12) return RitualState.Active;
        final yesterdayCompletion =
            await RitualCompletion.getByDateRangeAndRitualId(
                id, today.subtract(Duration(days: 1)), now, _db);
        if (yesterdayCompletion.isNotEmpty) return RitualState.Done;
        return RitualState.Skip;

      case RitualType.Weekly:
        int expectingDay = scheduleInformation;
        if (completion.isNotEmpty) return RitualState.Done;
        if (now.weekday == expectingDay) return RitualState.Active;
        final lastWeekCompletion =
            await RitualCompletion.getByDateRangeAndRitualId(
                id,
                today.subtract(
                    Duration(days: ((now.weekday - expectingDay) % 7))),
                now,
                _db);
        if (lastWeekCompletion.isNotEmpty) return RitualState.Done;
        return RitualState.Skip;
    }
    return RitualState.Active;
  }
}

class RitualsProvider {
  Future<Database> db;
  NotificationProvider _notificationProvider;

  RitualsProvider(path, this._notificationProvider) {
    _open(path);
  }

  void _open(String path) async {
    db = new Future(() {
      final dbInitial = openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        print("Creating tables");
        await db.execute(Ritual.getTableCreation());
        await db.execute(RitualCompletion.getTableCreation());
        await db.execute(RitualStep.getTableCreation());
      });
      // Assure there is a ritual 0
      return dbInitial.then((dbReady) async {
        Ritual ritual;
        ritual = await Ritual.get(1, dbReady).catchError((e) async {
          print("Creating evening ritual. $e");
          ritual = await Ritual.insert(
              "Evening ritual", RitualType.Evening, dbReady);
          await ritual.insertStep(
              "Check emails", "You don't want to forget something.");
          await ritual.insertStep(
              "Say the magic words", "Paolov dog you know.");
        });
        return dbInitial;
      });
    });
  }

  Future<Ritual> createRitual(String title, RitualType type,
      {int scheduleInformation}) {
    return db.then((dbReady) {
      final ritual = Ritual.insert(title, type, dbReady,
          scheduleInformation: scheduleInformation);
      _notificationProvider.armNotification(ritual);
      return ritual;
    });
  }

  Future<Ritual> getRitual(int ritualId) async {
    return db.then((dbReady) => Ritual.get(ritualId, dbReady));
  }

  Future<List<Ritual>> getRituals(bool active) async {
    return db.then((dbReady) async {
      var first = Ritual.getRituals(dbReady);
      if (active) {
        var value = await first;
        var result = new List<Ritual>();
        var futures = value.map((ritual) async {
          if ((await ritual.getState()) == RitualState.Active) {
            result.add(ritual);
          }
        });
        await Future.wait(futures);
        return result;
      }
      return first;
    });
  }

  Future close() async => db.then((dbReady) => dbReady.close());
}
