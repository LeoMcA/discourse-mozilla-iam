export default {
  setupComponent(args, component) {
    var user = args.model

    var old_nda = !!user.groups.find(e => { return e.name == 'mozillians_nda' })
    component.set('old_nda', old_nda)

    var mozillians_primary_email = user.mozilla_iam.mozillians_primary_email
    if (mozillians_primary_email && mozillians_primary_email != user.email) {
      component.set('mozillians_primary_email_mismatch', true)
      component.set('email', mozillians_primary_email)
    } else {
      component.set('email', user.email)
    }

    var provider = user.mozilla_iam.uid.split('|')[0]
    if (provider == 'github') {
      component.set('github', true)
    }

    var new_nda = !!user.groups.find(e => { return e.name == 'nda' })
    component.set('new_nda', new_nda)
  }
}
