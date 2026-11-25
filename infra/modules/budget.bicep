// Budget on the environment's resource group with alerts at 50 and 100 percent (ADR 0021).
param name string
param amountGbp int
param alertEmail string
@description('First day of the current month. Azure refuses a new monthly budget whose start date is in an earlier month, so the date cannot be fixed in the template; the default is computed when the deployment starts.')
param startDate string = utcNow('yyyy-MM-01')

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
