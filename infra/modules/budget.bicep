// Budget on the environment's resource group with alerts at 50 and 100 percent (ADR 0021).
param name string
param amountGbp int
param alertEmail string

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: name
  properties: {
    category: 'Cost'
    amount: amountGbp
    timeGrain: 'Monthly'
    timePeriod: { startDate: '2026-10-01' }
    notifications: {
      half: { enabled: true, operator: 'GreaterThan', threshold: 50, contactEmails: [ alertEmail ], thresholdType: 'Actual' }
      full: { enabled: true, operator: 'GreaterThan', threshold: 100, contactEmails: [ alertEmail ], thresholdType: 'Actual' }
    }
  }
}
