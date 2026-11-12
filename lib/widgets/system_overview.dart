import 'package:flutter/material.dart';

import '../models/steam_simulation.dart';
import '../theme/app_theme.dart';
import 'status_tag.dart';

class SystemOverview extends StatelessWidget {
  const SystemOverview({super.key, required this.simulation});

  final SteamSimulation simulation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Схема системы',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Поток пара и возврат конденсата',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: .06)),
              ),
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth > 680
                    ? _HorizontalDiagram(simulation: simulation)
                    : _VerticalDiagram(simulation: simulation),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _Legend(color: AppColors.steam, label: 'Пар'),
              _Legend(color: AppColors.water, label: 'Конденсат'),
              _Legend(color: AppColors.danger, label: 'Сброс давления'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  title: 'КОТЁЛ',
                  value: simulation.boilerPressure.toStringAsFixed(1),
                  unit: 'бар',
                  color: simulation.safetyValveOpen
                      ? AppColors.danger
                      : AppColors.steam,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  title: 'МАГИСТРАЛЬ',
                  value: simulation.workingPressure.toStringAsFixed(1),
                  unit: 'бар',
                  color: AppColors.steam,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  title: 'ГРЕЛКИ',
                  value: simulation.heaterTemperature.toStringAsFixed(0),
                  unit: '°C',
                  color: AppColors.water,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizontalDiagram extends StatelessWidget {
  const _HorizontalDiagram({required this.simulation});

  final SteamSimulation simulation;

  @override
  Widget build(BuildContext context) {
    final nodes = [
      _ProcessNode(
        icon: Icons.local_fire_department,
        title: 'Котёл',
        subtitle: '${simulation.boilerPressure.toStringAsFixed(1)} бар',
        color: simulation.safetyValveOpen ? AppColors.danger : AppColors.steam,
        active: simulation.isRunning,
      ),
      _ProcessNode(
        icon: Icons.tune,
        title: 'Клапаны',
        subtitle:
            simulation.reducerFailed ? 'Отказ редуктора' : 'Редукция · защита',
        color: simulation.reducerFailed ? AppColors.danger : AppColors.steam,
        active: simulation.isRunning,
      ),
      _ProcessNode(
        icon: Icons.water_drop_outlined,
        title: 'Сепаратор',
        subtitle: 'Сухость ${simulation.steamQuality.toStringAsFixed(0)}%',
        color: AppColors.water,
        active: simulation.isRunning,
      ),
      _ProcessNode(
        icon: Icons.hub_outlined,
        title: 'Распределение',
        subtitle: '${simulation.steamFlow.toStringAsFixed(0)}% потока',
        color: AppColors.steam,
        active: simulation.isRunning,
      ),
      _ProcessNode(
        icon: Icons.radar,
        title: 'Грелки',
        subtitle: '${simulation.heaterTemperature.toStringAsFixed(0)} °C',
        color: AppColors.water,
        active: simulation.isRunning && simulation.steamFlow > 0,
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var index = 0; index < nodes.length; index++) ...[
                Expanded(child: nodes[index]),
                if (index < nodes.length - 1)
                  _FlowArrow(
                    color:
                        simulation.isRunning ? AppColors.steam : Colors.white24,
                    animated: simulation.isRunning,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 2,
                color: simulation.isRunning && simulation.returnFlow > 1
                    ? AppColors.water
                    : Colors.white12,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.south,
                size: 15, color: AppColors.water.withValues(alpha: .9)),
            const SizedBox(width: 8),
            Text(
              'Конденсат · ${simulation.returnFlow.toStringAsFixed(0)}%',
              style: const TextStyle(color: AppColors.water, fontSize: 12),
            ),
            const SizedBox(width: 12),
          ],
        ),
        const SizedBox(height: 13),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Грелки → конденсатная коробка → клапан 13 → тёплый ящик',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            if (simulation.safetyValveOpen)
              const StatusTag(label: 'СБРОС ПАРА', color: AppColors.danger),
          ],
        ),
      ],
    );
  }
}

class _VerticalDiagram extends StatelessWidget {
  const _VerticalDiagram({required this.simulation});

  final SteamSimulation simulation;

  @override
  Widget build(BuildContext context) {
    final stages = [
      (
        '01',
        'Паровой котёл',
        '${simulation.boilerPressure.toStringAsFixed(1)} бар',
        Icons.local_fire_department,
        simulation.safetyValveOpen ? AppColors.danger : AppColors.steam,
      ),
      (
        '02',
        'Редукционный и предохранительный клапаны',
        simulation.reducerFailed
            ? 'Отказ редуктора'
            : 'Рабочее давление ${simulation.workingPressure.toStringAsFixed(1)} бар',
        Icons.tune,
        simulation.reducerFailed || simulation.safetyValveOpen
            ? AppColors.danger
            : AppColors.steam,
      ),
      (
        '03',
        'Сепаратор и распределительная коробка',
        'Осушение пара · качество ${simulation.steamQuality.toStringAsFixed(0)}%',
        Icons.water_drop_outlined,
        AppColors.water,
      ),
      (
        '04',
        'Отопительная магистраль → грелки',
        'Клапан 8: ${simulation.inletValve.toStringAsFixed(0)}% · ${simulation.heaterTemperature.toStringAsFixed(0)} °C',
        Icons.device_thermostat,
        AppColors.steam,
      ),
      (
        '05',
        'Конденсатная коробка → тёплый ящик',
        'Клапан 13 · возврат ${simulation.returnFlow.toStringAsFixed(0)}%',
        Icons.water,
        AppColors.water,
      ),
    ];

    return Column(
      children: [
        for (var index = 0; index < stages.length; index++) ...[
          Expanded(
            child: _VerticalStage(
              number: stages[index].$1,
              title: stages[index].$2,
              subtitle: stages[index].$3,
              icon: stages[index].$4,
              color: stages[index].$5,
              active: simulation.isRunning,
            ),
          ),
          if (index < stages.length - 1)
            SizedBox(
              height: 13,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(left: 19),
                  width: 2,
                  color: simulation.isRunning
                      ? (index == 3 ? AppColors.water : AppColors.steam)
                      : Colors.white12,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _ProcessNode extends StatelessWidget {
  const _ProcessNode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? color.withValues(alpha: .48) : Colors.white10,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  const _FlowArrow({required this.color, required this.animated});

  final Color color;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 25,
      child: Icon(Icons.chevron_right, color: color, size: animated ? 23 : 18),
    );
  }
}

class _VerticalStage extends StatelessWidget {
  const _VerticalStage({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.active,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: active ? color.withValues(alpha: .36) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Text(number,
              style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          const SizedBox(width: 12),
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String title;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text(unit,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}
