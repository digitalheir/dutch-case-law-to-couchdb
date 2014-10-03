# Class containing secret stuff. Do not add to version control.
module Secret
  CLOUDANT_NAME = 'rechtspraak'
  CLOUDANT_PASSWORD = ENV['CLOUDANT_PASSWORD']

  LAWLY_NAME = 'rechtspraak'
  LAWLY_PASSWORD = ENV['LAWLY_PASSWORD']
end