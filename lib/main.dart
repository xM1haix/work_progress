import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  runApp(const MyApp());
}

///Convert the progress to Color from [start] to [end]
Color getColorAtStep(Color start, Color end, double ratio) => Color.fromARGB(
      (start.a + (end.a - start.a) * ratio).round(),
      (start.r + (end.r - start.r) * ratio).round(),
      (start.g + (end.g - start.g) * ratio).round(),
      (start.b + (end.b - start.b) * ratio).round(),
    );

///[Future] which gets the data from [SharedPreferences] and thorw an
///[Exception] if at least a data was not found or return [Data]
Future<Data> getData() async {
  final s = await SharedPreferences.getInstance();
  final title = s.getString("title");
  final done = s.getInt("done");
  final total = s.getInt("total");
  if (done == null || title == null || total == null) {
    throw Exception("No data found");
  }
  debugPrint(title);
  debugPrint(done.toString());
  debugPrint(total.toString());
  return Data(
    title: title,
    done: done,
    total: total,
  );
}

///The object which holds all the data about the task
class Data {
  ///
  const Data({
    required this.title,
    required int done,
    required this.total,
  }) : _done = done;
  final int _done;

  ///The amount you need to do
  final int total;

  ///The text which has the shortest description of it
  final String title;

  ///The color of the bar
  Color get bar =>
      getColorAtStep(const Color(0xFFFF0000), const Color(0xFF00FF00), ratio);

  ///The value done
  ///it s clamped to 0 and [total]
  int get done => _done.clamp(0, total);

  ///The ratio between [done] and [total]
  double get ratio => total == 0 ? 0 : done / total;

  ///The text color based on project
  Color get text =>
      getColorAtStep(const Color(0xFFFFFFFF), const Color(0xFF000000), ratio);
}

///Main skelethon of the app
class MyApp extends StatelessWidget {
  ///
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Work Progress",
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}

///Main skelethon of the app
class MyHomePage extends StatefulWidget {
  ///
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late var _title = "Loading";
  late Future<Data> _future;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: Text(_title),
        actions: [
          IconButton(
            onPressed: set,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () async {
                  final s = await SharedPreferences.getInstance();
                  if (snapshot.data!.done >= snapshot.data!.total) {
                    return;
                  }
                  await s.setInt("done", snapshot.data!.done + 1);
                  _init();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    height: 400,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white, width: 0),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        AnimatedContainer(
                          height: snapshot.data!.ratio * 400,
                          width: 150,
                          decoration: BoxDecoration(
                            color: snapshot.data!.bar,
                            borderRadius: BorderRadius.circular(27),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                        Center(
                          child: Text(
                            """Έκανες το ${snapshot.data!.done} από το ${snapshot.data!.total}""",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              color: snapshot.data!.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> set() async {
    final title = TextEditingController();
    final done = TextEditingController();
    final total = TextEditingController();
    final x = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              (title, "Title", false),
              (done, "Done", true),
              (total, "Total", true),
            ]
                .map(
                  (e) => TextField(
                    controller: e.$1,
                    keyboardType: e.$3 ? TextInputType.number : null,
                    inputFormatters: e.$3
                        ? [
                            FilteringTextInputFormatter.allow(
                              RegExp(r"^\d*$"),
                            ),
                          ]
                        : null,
                    decoration: InputDecoration(
                      hintText: e.$2,
                      labelText: e.$2,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [("Save", true), ("Cancel", false)]
            .map(
              (e) => TextButton(
                onPressed: () => Navigator.of(context).pop(e.$2),
                child: Text(e.$1),
              ),
            )
            .toList(),
      ),
    );
    if (x != true) {
      return;
    }
    final s = await SharedPreferences.getInstance();
    await s.setString("title", title.text);
    await s.setInt("done", done.text.isEmpty ? 0 : int.parse(done.text));
    await s.setInt("total", total.text.isEmpty ? 0 : int.parse(total.text));
    _init();
  }

  void _init() {
    setState(() {
      _future = getData().then((e) {
        setState(() {
          _title = e.title;
        });
        return e;
      });
    });
  }
}
