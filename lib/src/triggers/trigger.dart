// Copyright (c) 2016, Herman Bergwerf. All rights reserved.
// Use of this source code is governed by an AGPL-3.0-style license
// that can be found in the LICENSE file.

part of bromium;

// ignore: one_member_abstracts
abstract class TriggerCondition {
  bool check(Simulation sim);
}

// ignore: one_member_abstracts
abstract class TriggerAction {
  void run(Simulation sim);
}

// A simulation trigger
class Trigger {
  // Trigger only once
  final bool triggerOnce;

  // Number or executed triggers
  int triggerCount = 0;

  // Trigger conditions
  final List<TriggerCondition> conditions;

  // Trigger actions
  final List<TriggerAction> actions;

  // Constructor for permanent trigger
  Trigger(this.conditions, this.actions) : triggerOnce = false;

  // Constructor for one-time trigger
  Trigger.once(this.conditions, this.actions) : triggerOnce = true;

  // Check if all conditions are met.
  bool check(Simulation sim) {
    if (triggerOnce && triggerCount == 0 || !triggerOnce) {
      for (var condition in conditions) {
        if (!condition.check(sim)) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  // Run the trigger.
  void run(Simulation sim) {
    triggerCount++;
    for (var action in actions) {
      action.run(sim);
    }
  }
}
