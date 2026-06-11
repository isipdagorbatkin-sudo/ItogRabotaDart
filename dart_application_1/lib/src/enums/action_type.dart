enum ActionType {
  start,
  add,
  delete,
  edit,
  search,
  list,
  stats,
  viewLogs,
  report,
  exit,
  error,
}

String actionName(ActionType type) {
  switch (type) {
    case ActionType.start:
      return 'START';
    case ActionType.add:
      return 'ADD';
    case ActionType.delete:
      return 'DELETE';
    case ActionType.edit:
      return 'EDIT';
    case ActionType.search:
      return 'SEARCH';
    case ActionType.list:
      return 'LIST';
    case ActionType.stats:
      return 'STATS';
    case ActionType.viewLogs:
      return 'VIEW_LOGS';
    case ActionType.report:
      return 'REPORT';
    case ActionType.exit:
      return 'EXIT';
    case ActionType.error:
      return 'ERROR';
  }
}
