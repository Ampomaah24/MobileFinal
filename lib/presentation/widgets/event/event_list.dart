import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/event_model.dart';
import '../../../core/services/event_service.dart';
import 'event_card.dart';
import '../../../common/loading_indicator.dart';

class EventList extends StatelessWidget {
  final List<EventModel>? events;
  final bool showLoading;
  final String emptyMessage;
  final String emptySubMessage;
  final IconData emptyIcon;
  final bool isHorizontal;
  final double? itemWidth;
  final bool showFilterChip;
  final Function(EventModel)? onEventTap;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const EventList({
    Key? key,
    this.events,
    this.showLoading = false,
    this.emptyMessage = 'No events found',
    this.emptySubMessage = 'Check back later for updates or try different filters',
    this.emptyIcon = Icons.event_busy,
    this.isHorizontal = false,
    this.itemWidth,
    this.showFilterChip = false,
    this.onEventTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.physics,
    this.shrinkWrap = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If events list is provided, use it; otherwise get it from the EventService
    final eventList = events ?? Provider.of<EventService>(context).filteredEvents;
    final isLoading = showLoading || Provider.of<EventService>(context).isLoading;

    if (isLoading) {
      return const Center(
        child: LoadingIndicator(
          size: LoadingSize.medium,
          message: 'Loading events...',
        ),
      );
    }

    if (eventList.isEmpty) {
      return _buildEmptyState(context);
    }

    if (isHorizontal) {
      return _buildHorizontalList(context, eventList);
    } else {
      return _buildVerticalList(context, eventList);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              emptySubMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (showFilterChip) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Reset filters
                  Provider.of<EventService>(context, listen: false).resetFilters();
                },
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List<EventModel> eventList) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: eventList.length,
        itemBuilder: (context, index) {
          final event = eventList[index];
          return EventCard(
            event: event,
            width: itemWidth ?? 280,
            onTap: () => _handleEventTap(context, event),
          );
        },
      ),
    );
  }

  Widget _buildVerticalList(BuildContext context, List<EventModel> eventList) {
    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: eventList.length,
      itemBuilder: (context, index) {
        final event = eventList[index];
        return EventCard(
          event: event,
          isHorizontal: true,
          onTap: () => _handleEventTap(context, event),
        );
      },
    );
  }

  void _handleEventTap(BuildContext context, EventModel event) {
    if (onEventTap != null) {
      onEventTap!(event);
    } else {
      Navigator.pushNamed(
        context,
        '/event-details',
        arguments: event.id,
      );
    }
  }
}

// Filter chips for categories
class EventCategoryFilters extends StatelessWidget {
  final List<String>? categories;
  final String? selectedCategory;
  final Function(String?)? onCategorySelected;
  final bool showAllOption;
  final String allLabel;

  const EventCategoryFilters({
    Key? key,
    this.categories,
    this.selectedCategory,
    this.onCategorySelected,
    this.showAllOption = true,
    this.allLabel = 'All',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventService = Provider.of<EventService>(context);
    final availableCategories = categories ?? eventService.getCategories();
    final selected = selectedCategory ?? eventService.selectedCategory;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (showAllOption)
            _buildCategoryChip(
              context,
              allLabel,
              null,
              selected,
              onCategorySelected ?? eventService.setSelectedCategory,
            ),
          ...availableCategories.map((category) {
            return _buildCategoryChip(
              context,
              category,
              category,
              selected,
              onCategorySelected ?? eventService.setSelectedCategory,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    String? category,
    String? selected,
    Function(String?) onSelected,
  ) {
    final isSelected = selected == category;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (value) {
          onSelected(value ? category : null);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: theme.primaryColor.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isSelected ? theme.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: theme.primaryColor,
      ),
    );
  }
}