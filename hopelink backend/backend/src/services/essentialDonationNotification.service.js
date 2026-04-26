export const notifyOrganizationOnNewCommitment = async ({
  organizationId,
  requestId,
  commitmentId,
  userId,
}) => {
  console.info('[Notification Placeholder] New commitment created', {
    organizationId,
    requestId,
    commitmentId,
    userId,
  });
};

export const notifyUsersOnRequestClosed = async ({
  requestId,
  organizationId,
}) => {
  console.info('[Notification Placeholder] Essential request closed', {
    requestId,
    organizationId,
  });
};

export default {
  notifyOrganizationOnNewCommitment,
  notifyUsersOnRequestClosed,
};
