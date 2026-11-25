// Budget on the environment's resource group with alerts at 50 and 100 percent (ADR 0021).
param name string
param amountGbp int
param alertEmail string
@description('Start date, first of a month. A new budget must start in the current month and an existing budget\'s start date cannot change, so the Deploy workflow passes the existing value when there is one and the first of the current month when there is not.')
param startDate string

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: name
  properties: {
    category: 'Cost'
    amount: amountGbp
    timeGrain: 'Monthly'
    timePeriod: { startDate: startDate }
    notifications: {
      half: { enabled: true, operator: 'GreaterThan', threshold: 50, contactEmails: [ alertEmail ], thresholdType: 'Actual' }
      full: { enabled: true, operator: 'GreaterThan', threshold: 100, contactEmails: [ alertEmail ], thresholdType: 'Actual' }
    }
  }
}
