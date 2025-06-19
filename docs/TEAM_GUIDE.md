# Team Guide: Load Testing Scheduler

## Overview

This guide explains how teams can use the Load Testing Scheduler to book time slots in the shared preprod environment.

## Step-by-Step Process

### 1. Planning Your Load Test

Before booking a time slot, prepare:

- **Test objectives**: What are you trying to validate?
- **Test scenario**: Which user flows will you test?
- **Expected load**: How many concurrent users or requests/second?
- **Success criteria**: How will you measure success?
- **Duration estimate**: How long do you need (including setup/teardown)?

### 2. Checking Availability

1. Review the current schedule in [`config/schedules.json`](../config/schedules.json)
2. Remember the 30-minute buffer requirement between tests
3. Plan for business hours (9 AM - 6 PM UTC, weekdays)
4. Book at least 48 hours in advance

### 3. Creating a Time Slot Request

1. Go to [GitHub Issues](../../issues)
2. Click **New Issue**
3. Select **Load Test Time Slot Request** template
4. Fill in all required fields:

#### Required Information

| Field | Description | Example |
|-------|-------------|---------|
| **Team** | Your team name | `team-alpha` |
| **Contact Person** | GitHub username | `@alice` |
| **Slack Channel** | Team notification channel | `#team-alpha` |
| **Date/Time** | Start time in UTC | `2025-01-20T14:00:00Z` |
| **Duration** | Test length | `120 minutes` |
| **Test Type** | Type of load test | `load` |
| **Priority** | Urgency level | `P2 - Normal` |
| **App Version** | Version to test | `v2.1.0` |
| **Expected Load** | Load description | `1000 concurrent users` |

#### Optional but Recommended

- **Test Scenario**: Detailed description of what you're testing
- **Success Criteria**: How you'll measure success
- **Prerequisites checklist**: Confirm you've prepared

### 4. SRE Review Process

After submitting your request:

1. **Automatic validation**: System checks for conflicts
2. **SRE review**: Team reviews your request (usually within 4 hours)
3. **Approval/modification**: Either approved or feedback provided
4. **Scheduling**: SRE runs the manual workflow to book your slot

### 5. Confirmation and Notifications

Once approved:

- ✅ **GitHub issue closed** with confirmation details
- 📱 **Slack notification** sent to your team channel
- 📅 **Calendar entry** added to shared preprod calendar

### 6. Test Day

#### Before Your Test

- [ ] Verify your application version is deployed
- [ ] Prepare test data and scripts
- [ ] Join your team's Slack channel for notifications
- [ ] Have monitoring dashboards ready

#### During Your Test

- [ ] Monitor the automated start notification
- [ ] Watch your application metrics
- [ ] Be ready to stop the test if issues arise
- [ ] Document any issues or findings

#### After Your Test

- [ ] Wait for automatic cleanup (30-minute buffer)
- [ ] Review and document results
- [ ] Clean up any test data you created
- [ ] Share findings with your team

## Best Practices

### 🎯 Test Planning

- **Start small**: Begin with shorter duration tests
- **Realistic scenarios**: Use production-like user behavior
- **Gradual ramp-up**: Don't jump straight to peak load
- **Monitor everything**: Application, database, infrastructure

### ⏰ Scheduling

- **Book early**: 48-hour minimum lead time
- **Buffer time**: Add extra time for setup and unexpected issues
- **Team coordination**: Ensure your team is available during the test
- **Backup plans**: Have alternative time slots ready

### 🔧 Technical Preparation

- **Environment validation**: Ensure preprod is in good state
- **Test data**: Prepare realistic, anonymized data
- **Monitoring setup**: Configure alerts and dashboards
- **Rollback plan**: Know how to quickly stop if needed

### 📊 Documentation

- **Test objectives**: Clear goals and success criteria
- **Results documentation**: Share findings with the team
- **Lessons learned**: Document issues and improvements
- **Next steps**: Plan follow-up tests if needed

## Common Scenarios

### Regular Load Testing

```yaml
Team: team-alpha
Duration: 60 minutes
Test Type: load
Priority: P2 - Normal
Expected Load: 500 concurrent users
Scenario: User registration and checkout flow
```

### Performance Regression Testing

```yaml
Team: team-beta
Duration: 90 minutes
Test Type: load
Priority: P1 - High
Expected Load: 1000 concurrent users
Scenario: API performance after new feature deployment
```

### Capacity Planning

```yaml
Team: team-gamma
Duration: 180 minutes
Test Type: stress
Priority: P2 - Normal
Expected Load: 2000 concurrent users
Scenario: Black Friday traffic simulation
```

### Emergency Debugging

```yaml
Team: sre-team
Duration: 30 minutes
Test Type: spike
Priority: P0 - Critical
Expected Load: 1500 concurrent users
Scenario: Reproduce production issue in preprod
```

## Team Limits and SLA

### Resource Limits

- **Maximum duration**: 4 hours per test slot
- **Weekly limit**: 8 hours per team (negotiable)
- **Concurrent tests**: Only one test per time slot
- **Buffer time**: 30 minutes between all tests

### Service Level Agreement

| Metric | Target |
|--------|--------|
| **Booking lead time** | 48 hours minimum |
| **SRE review time** | 4 hours during business hours |
| **Environment availability** | 95% during business hours |
| **Notification delivery** | < 5 minutes |

### Emergency Procedures

For **P0 Critical** tests:

1. Create issue with P0 priority
2. Ping `@sre-team` in Slack emergency channel
3. Call the on-call SRE if no response in 30 minutes
4. Emergency slots may override existing P2 tests

## Troubleshooting

### Issue: "Time slot conflicts with existing tests"

**Solution**: Check [`config/schedules.json`](../config/schedules.json) and choose a different time

### Issue: "Team authorization failed"

**Solutions**:
- Verify you're in the correct GitHub team
- Ask your team lead to add you to the team
- Contact SRE if team configuration is incorrect

### Issue: "Test didn't start automatically"

**Solutions**:
- Check if it's outside business hours (tests pause overnight)
- Verify the schedule processor workflow is running
- Check GitHub Actions logs for errors

### Issue: "Environment is unstable"

**Solutions**:
- Check preprod status dashboard
- Contact SRE team for environment health check
- Consider rescheduling if major issues exist

## Getting Help

### Documentation

- 📖 **Main README**: [`README.md`](../README.md)
- 🔧 **API Documentation**: [`docs/API.md`](./API.md)
- 🚀 **Deployment Guide**: [`docs/DEPLOYMENT.md`](./DEPLOYMENT.md)

### Support Channels

- 💬 **General questions**: `#preprod-support` Slack channel
- 🚨 **Emergency support**: `#sre-emergency` Slack channel
- 🐛 **Bug reports**: [GitHub Issues](../../issues) with "bug" label
- 📧 **SRE team**: Tag `@sre-team` in issues or Slack

### Escalation Path

1. **Level 1**: Check documentation and common solutions
2. **Level 2**: Ask in `#preprod-support` Slack channel
3. **Level 3**: Create GitHub issue with detailed information
4. **Level 4**: Contact SRE on-call for emergencies

---

**Need immediate help?** Join the [`#sre-emergency`](https://your-company.slack.com/channels/sre-emergency) Slack channel.