import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  runApp(const MyApp());
}

Color getColorAtStep(Color start, Color end, double ratio) => Color.fromARGB(
      (start.a + (end.a - start.a) * ratio).round(),
      (start.r + (end.r - start.r) * ratio).round(),
      (start.g + (end.g - start.g) * ratio).round(),
      (start.b + (end.b - start.b) * ratio).round(),
    );

Future<Data> getData() async {
  final s = await SharedPreferences.getInstance();
  if (s.getInt("done") == null ||
      s.getString("title") == null ||
      s.getInt("total") == null) {
    throw Exception("No data found");
  }

  debugPrint(s.getString("title"));
  debugPrint(s.getInt("done").toString());
  debugPrint(s.getInt("total").toString());
  return Data(
    title: s.getString("title")!,
    done: s.getInt("done")!,
    total: s.getInt("total")!,
  );
}

class Data {
  const Data({
    required this.title,
    required int done,
    required this.total,
  }) : _done = done;
  final int _done;
  final int total;
  final String title;
  Color get bar =>
      getColorAtStep(const Color(0xFFFF0000), const Color(0xFF00FF00), ratio);
  int get done => _done.clamp(0, total);
  double get ratio => total == 0 ? 0 : done / total;
  Color get text =>
      getColorAtStep(const Color(0xFFFFFFFF), const Color(0xFF000000), ratio);
}

class MyApp extends StatelessWidget {
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

class MyHomePage extends StatefulWidget {
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
        builder: (context, snapshot) => snapshot.hasError
            ? Center(child: Text(snapshot.error.toString()))
            : snapshot.hasData
                ? SingleChildScrollView(
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
                                    "Έκανες το ${snapshot.data!.done} από το ${snapshot.data!.total}",
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
                  )
                : const CircularProgressIndicator(),
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
