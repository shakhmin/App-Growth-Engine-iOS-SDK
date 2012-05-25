
# 2012-05-21:

Updated signature for <code>newReferral</code> to support patient name. The message template is now configured on the portal.

<pre>
- (BOOL) newReferral:(NSArray *)phones withName:(NSString *)name useVirtualNumber:(BOOL) sendNow;
</pre>

Updated signature for <pre>discover</pre> to support limit for the number of contacts.

<pre>
- (BOOL) discover: (int) limit;
</pre>

