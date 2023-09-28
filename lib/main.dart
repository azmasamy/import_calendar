import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

enum CalendarScreenState { init, loading, loaded }

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();
  CalendarScreenState state = CalendarScreenState.init;
  List<Calendar> calendars = [];
  List<Event> events = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBody(),
    );
  }

  buildBody() {
    switch (state) {
      case CalendarScreenState.init:
        return Center(
          child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  state = CalendarScreenState.loading;
                });
                if ((await Permission.calendar.request()).isGranted) {
                  calendars = (await deviceCalendarPlugin.retrieveCalendars())
                      .data as List<Calendar>;
                  final startDate =
                      DateTime.now().add(const Duration(days: -30));
                  final endDate = DateTime.now().add(const Duration(days: 30));
                  for (int i = 0; i < calendars.length; i++) {
                    final calendarEvents =
                        await deviceCalendarPlugin.retrieveEvents(
                            calendars[i].id,
                            RetrieveEventsParams(
                              startDate: startDate,
                              endDate: endDate,
                            ));
                    events.addAll(calendarEvents.data as List<Event>);
                  }
                  setState(() {
                    state = CalendarScreenState.loaded;
                  });
                } else {
                  setState(() {
                    state = CalendarScreenState.init;
                  });
                }
              },
              child: const Text("Import Calendar")),
        );
      case CalendarScreenState.loading:
        return const Center(child: CircularProgressIndicator());
      case CalendarScreenState.loaded:
        return SafeArea(
            child: ListView.builder(
          itemCount: calendars.length,
          itemBuilder: (context, index) => ListTile(
              titleAlignment: ListTileTitleAlignment.top,
              leading: Text(calendars[index].id!),
              title: Text(calendars[index].accountName!),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(calendars[index].accountType!),
                  Text(calendars[index].name!),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    itemBuilder: (context, index) => ListTile(
                      titleAlignment: ListTileTitleAlignment.top,
                      leading: Text(events[index].eventId!),
                      title: Text(events[index].title!),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(events[index].description!),
                          Row(
                            children: [
                              Text(
                                  "${events[index].start!.year.toString()}/${events[index].start!.month.toString()}/${events[index].start!.day.toString()}"),
                              const Text("-"),
                              Text(
                                  "${events[index].end!.year.toString()}/${events[index].end!.month.toString()}/${events[index].end!.day.toString()}"),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                ],
              )),
        ));
    }
  }
}
