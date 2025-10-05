import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/event_weather_prediction_service.dart';
import '../theme/app_theme.dart';
import 'animated_widgets.dart';

/// Widget que exibe análise climática de um evento com visual moderno
class EventWeatherCard extends StatelessWidget {
  final EventWeatherAnalysis analysis;
  final VoidCallback? onTap;
  final bool compact;

  const EventWeatherCard({
    super.key,
    required this.analysis,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (compact) {
      return _buildCompactCard(theme, isDark);
    }

    return AnimatedGlassCard(
      delay: 0,
      isDark: isDark,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildRiskIndicator(theme),
          if (analysis.aiInsight != null) ...[
            const SizedBox(height: 16),
            _buildAIInsight(theme, isDark),
          ],
          if (analysis.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSuggestions(theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: analysis.riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: analysis.riskColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: analysis.riskColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(analysis.riskIcon, color: analysis.riskColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.activity.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  analysis.riskLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: analysis.riskColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (analysis.daysUntilEvent <= 7)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.lightWarning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${analysis.daysUntilEvent}d',
                style: TextStyle(
                  color: AppTheme.lightWarning,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        // Ícone do tipo de atividade
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            analysis.activity.type.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                analysis.activity.title,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.textTheme.bodyMedium!.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(analysis.activity.date),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.textTheme.bodyMedium!.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    analysis.daysUntilEvent == 0
                        ? 'Hoje'
                        : analysis.daysUntilEvent == 1
                        ? 'Amanhã'
                        : 'Em ${analysis.daysUntilEvent} dias',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiskIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: analysis.riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: analysis.riskColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(analysis.riskIcon, color: analysis.riskColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.riskLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: analysis.riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.riskDescription,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsight(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.darkPrimary.withValues(alpha: 0.2),
                  AppTheme.darkSecondary.withValues(alpha: 0.2),
                ]
              : [
                  AppTheme.lightPrimary.withValues(alpha: 0.1),
                  AppTheme.lightSecondary.withValues(alpha: 0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('🤖', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              Text(
                'Análise Inteligente',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.aiInsight!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendações',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...analysis.suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSuggestionItem(suggestion, theme),
          );
        }),
      ],
    );
  }

  Widget _buildSuggestionItem(EventSuggestion suggestion, ThemeData theme) {
    Color priorityColor;
    switch (suggestion.priority) {
      case SuggestionPriority.high:
        priorityColor = AppTheme.lightError;
        break;
      case SuggestionPriority.medium:
        priorityColor = AppTheme.lightWarning;
        break;
      case SuggestionPriority.low:
        priorityColor = AppTheme.lightSuccess;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(suggestion.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(suggestion.description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para listar múltiplos eventos com análise
class EventsWeatherList extends StatelessWidget {
  final List<EventWeatherAnalysis> analyses;
  final Function(EventWeatherAnalysis)? onTap;

  const EventsWeatherList({super.key, required this.analyses, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Ordernar por risco (crítico primeiro) e depois por data
    final sortedAnalyses = List<EventWeatherAnalysis>.from(analyses)
      ..sort((a, b) {
        // Primeiro por nível de risco
        final riskCompare = _riskValue(b.risk).compareTo(_riskValue(a.risk));
        if (riskCompare != 0) return riskCompare;

        // Depois por proximidade da data
        return a.daysUntilEvent.compareTo(b.daysUntilEvent);
      });

    return Column(
      children: sortedAnalyses.map((analysis) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EventWeatherCard(
            analysis: analysis,
            compact: true,
            onTap: onTap != null ? () => onTap!(analysis) : null,
          ),
        );
      }).toList(),
    );
  }

  int _riskValue(EventWeatherRisk risk) {
    switch (risk) {
      case EventWeatherRisk.critical:
        return 3;
      case EventWeatherRisk.warning:
        return 2;
      case EventWeatherRisk.safe:
        return 1;
      case EventWeatherRisk.unknown:
        return 0;
    }
  }
}
