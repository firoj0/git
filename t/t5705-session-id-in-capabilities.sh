#!/bin/sh

test_description='session ID in capabilities'

. ./test-lib.sh

REPO="$(pwd)/repo"
LOCAL_PRISTINE="$(pwd)/local_pristine"

test_expect_success 'setup repos for session ID capability tests' '
	git init "$REPO" &&
	test_commit -C "$REPO" a &&
	git clone "file://$REPO" "$LOCAL_PRISTINE" &&
	test_commit -C "$REPO" b
'

for PROTO in 0 1 2
do
	test_expect_success "session IDs not advertised by default (fetch v${PROTO})" '
		test_when_finished "rm -rf local tr2-client-events" &&
		cp -r "$LOCAL_PRISTINE" local &&
		GIT_TRACE2_EVENT="$(pwd)/tr2-client-events" \
		git -c protocol.version=$PROTO -C local fetch origin &&
		test -z "$(grep \"key\":\"server-sid\" tr2-client-events)"
	'

	test_expect_success "session IDs not advertised by default (push v${PROTO})" '
		test_when_finished "rm -rf local tr2-client-events" &&
		cp -r "$LOCAL_PRISTINE" local &&
		git -C local pull --no-rebase origin &&
		GIT_TRACE2_EVENT_NESTING=5 \
		GIT_TRACE2_EVENT="$(pwd)/tr2-client-events" \
		git -c protocol.version=$PROTO -C local push origin &&
		test -z "$(grep \"key\":\"server-sid\" tr2-client-events)"
	'
done

test_expect_success 'enable SID advertisement' '
	git -C "$REPO" config transfer.advertiseSID true &&
	git -C "$LOCAL_PRISTINE" config transfer.advertiseSID true
'

for PROTO in 0 1 2
do
	test_expect_success "session IDs advertised (fetch v${PROTO})" '
		test_when_finished "rm -rf local tr2-client-events" &&
		cp -r "$LOCAL_PRISTINE" local &&
		GIT_TRACE2_EVENT="$(pwd)/tr2-client-events" \
		git -c protocol.version=$PROTO -C local fetch origin &&
		grep \"key\":\"server-sid\" tr2-client-events
	'

	test_expect_success "session IDs advertised (push v${PROTO})" '
		test_when_finished "rm -rf local tr2-client-events" &&
		cp -r "$LOCAL_PRISTINE" local &&
		git -C local pull --no-rebase origin &&
		GIT_TRACE2_EVENT_NESTING=5 \
		GIT_TRACE2_EVENT="$(pwd)/tr2-client-events" \
		git -c protocol.version=$PROTO -C local push origin &&
		grep \"key\":\"server-sid\" tr2-client-events
	'
done

test_done
