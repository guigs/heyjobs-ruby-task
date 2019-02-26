### Task background

We publish our jobs to different marketing sources. To keep track of where the particular job is published, we create
`Campaign` entity in database. `Campaigns` are periodically synchronized with 3rd party _Ad Service_.

`Campaign` properties:

- `id`
- `job_id`
- `status`: one of [active, paused, deleted]
- `external_reference`: corresponds to Ad’s ‘reference’
- `ad_description`: text description of an Ad

Due to various types of failures (_Ad Service_ inavailability, errors in campaign details etc.)
local `Campaigns` can fall out of sync with _Ad Service_.
So we need a way to detect discrepancies between local and remote state.

### Pre requisites

You should have sqlite installed. For example, in Ubuntu, run `sudo apt-get install libsqlite3-dev`
Then run `bundle install`

### Tests

Run `bundle exec rspec`

### How does it work

This lib implements `DiscrepanciesService` that get campaigns from external JSON API([example link](https://mockbin.org/bin/fcb30500-7b98-476f-810d-463a0b8fc3df)) and detect discrepancies between local and remote state.
The service will match local and remote campaigns by their remote reference and compare their attributes (currently `state` and `description`).

States are matched in the following way:

* Local `active` is equivalent to remote `enabled`;
* Local `paused` is equivalent to remote `disabled`;
* Local `deleted` is supposed not to have a matching remote campaign;

### Service output format

`DiscrepanciesService#call` will return an array with a hash for each campaign, with the attributes `remote_reference` and `discrepancies`.
The `discrepancies` attribute is an array with discrepancies. Each discrepancy is a hash with 3 attributes: `property`, `remote` and `local`.

High level example (with discrepancies details omitted):

```
[
  {
    remote_reference: "1",
    discrepancies: [...]
  },
  {
    remote_reference: "2",
    discrepancies: [...]
  }
]
```

When local and remote campaigns are found with no discrepant attributes the discrepancies array will be empty:

```
{
  remote_reference: "1",
  discrepancies: []
}
```

When local and remote campaigns are found with discrepant attributes:

```
{
  remote_reference: "2",
  discrepancies: [
    {
      property: "status",
      remote: "disabled",
      local: "active"
    },
    {
      propery: "description",
      remote: "Rails Engineer",
      local: "Ruby on Rails Developer"
    }
  ]
}
```

When local campaign for remote reference does not exist, the service will report discrepancy for all attributes, using `nil` for local values. 

```
{
  remote_reference: "3",
  discrepancies: [
    {
      property: "status",
      remote: "disabled",
      local: nil
    },
    {
      property: "description",
      remote: "Senior Rails Engineer",
      local: nil
    }
  ]
}
```

When remote campaign is not found, and local campaign status is not `'deleted'`, then the service will report discrepancy for all attributes, using `nil` for remote values. 

```
{
  remote_reference: "4",
  discrepancies: [
    {
      property: "status",
      remote: nil,
      local: "paused"
    },
    {
      property: "description",
      remote: nil,
      local: "Junior Rails Engineer"
    }
  ]
}
```
