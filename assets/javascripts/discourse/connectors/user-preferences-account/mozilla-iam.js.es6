export default {
  setupComponent(args, component) {
    var provider = args.model.mozilla_iam.uid.split('|')[0]
    console.log(provider)
    switch (true) {
      case provider == 'ad':
        component.set('check', true)
        component.set('provider', 'LDAP')
        break
      case provider == 'github':
        component.set('check', true)
        component.set('provider', 'GitHub')
        break
      case provider == 'google-oauth2':
        component.set('provider', 'Google')
        break
      default:
        component.set('provider', 'Passwordless')
    }
  }
}
