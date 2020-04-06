import 'dart:async';

import 'package:meta/meta.dart';
import 'package:time_tracker_flutter_course/app/home/models/entry.dart';
import 'package:time_tracker_flutter_course/app/home/models/event.dart';
import 'package:time_tracker_flutter_course/services/api_path.dart';
import 'package:time_tracker_flutter_course/services/firestore_service.dart';

abstract class Database {
  Future<void> setEvent(Event event);
  Future<void> deleteEvent(Event event);
  Stream<List<Event>> eventsStream();
  Stream<Event> eventStream({@required String eventId});

  Future<void> setEntry(Entry entry);
  Future<void> deleteEntry(Entry entry);
  Stream<List<Entry>> entriesStream({Event event});
}

String documentIdFromCurrentDate() => DateTime.now().toIso8601String();

class FirestoreDatabase implements Database {
  FirestoreDatabase({@required this.uid}) : assert(uid != null);
  final String uid;

  final _service = FirestoreService.instance;

  @override
  Future<void> setJob(Event event) async => await _service.setData(
        path: APIPath.event(uid, event.id),
        data: event.toMap(),
      );

  @override
  Future<void> deleteEvent(Event event) async {
    // delete where entry.eventId == event.eventId
    final allEntries = await entriesStream(event: event).first;
    for (Entry entry in allEntries) {
      if (entry.eventId == event.id) {
        await deleteEntry(entry);
      }
    }
    // delete event
    await _service.deleteData(path: APIPath.event(uid, event.id));
  }

  @override
  Stream<Event> eventStream({@required String eventId}) => _service.documentStream(
        path: APIPath.event(uid, eventId),
        builder: (data, documentId) => Event.fromMap(data, documentId),
      );

  @override
  Stream<List<Job>> eventsStream() => _service.collectionStream(
        path: APIPath.events(uid),
        builder: (data, documentId) => Event.fromMap(data, documentId),
      );

  @override
  Future<void> setEntry(Entry entry) async => await _service.setData(
        path: APIPath.entry(uid, entry.id),
        data: entry.toMap(),
      );

  @override
  Future<void> deleteEntry(Entry entry) async =>
      await _service.deleteData(path: APIPath.entry(uid, entry.id));

  @override
  Stream<List<Entry>> entriesStream({Event event}) =>
      _service.collectionStream<Entry>(
        path: APIPath.entries(uid),
        queryBuilder: job != null
            ? (query) => query.where('eventId', isEqualTo: event.id)
            : null,
        builder: (data, documentID) => Entry.fromMap(data, documentID),
        sort: (lhs, rhs) => rhs.start.compareTo(lhs.start),
      );
}
