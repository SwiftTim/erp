// lib/data/local/daos/calendar_dao.dart

import 'package:floor/floor.dart';
import '../../models/messaging_models.dart';

@dao
abstract class CalendarDao {
  @Query('SELECT * FROM calendar_events ORDER BY start_date ASC')
  Future<List<CalendarEvent>> getAllEvents();

  @Query('''
    SELECT * FROM calendar_events 
    WHERE start_date >= :fromMs AND start_date <= :toMs 
    ORDER BY start_date ASC
  ''')
  Future<List<CalendarEvent>> getEventsInRange(int fromMs, int toMs);

  @Query('''
    SELECT * FROM calendar_events 
    WHERE start_date >= :nowMs 
    ORDER BY start_date ASC
  ''')
  Future<List<CalendarEvent>> getUpcomingEvents(int nowMs);

  @Query('SELECT * FROM calendar_events WHERE id = :id')
  Future<CalendarEvent?> getEventById(String id);

  @insert
  Future<void> insertEvent(CalendarEvent event);

  @update
  Future<void> updateEvent(CalendarEvent event);

  @delete
  Future<void> deleteEvent(CalendarEvent event);

  @Query('''
    SELECT * FROM calendar_events 
    WHERE start_date BETWEEN :fromMs AND :toMs
    ORDER BY start_date ASC
  ''')
  Future<List<CalendarEvent>> getEventsForMonth(int fromMs, int toMs);
}
