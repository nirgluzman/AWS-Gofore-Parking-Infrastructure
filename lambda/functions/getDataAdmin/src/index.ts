// https://docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/javascript_dynamodb_code_examples.html
// https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBMapper.DataTypes.html

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, ScanCommand, ScanCommandOutput } from '@aws-sdk/lib-dynamodb';

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

// environment variables
const region = process.env.REGION;
const tableName = process.env.TABLE_NAME;

// initialize DynamoDB client
const ddbClient = new DynamoDBClient({ region });

// initialize DynamoDB DocumentClient
const docClient = DynamoDBDocumentClient.from(ddbClient);

// format the time portion according to the UK locale and the Europe/Rome time zone
const formatTimeOrBlank = (timeStampString: string) => {
  const timeStamp = new Date(timeStampString).toLocaleTimeString('en-GB', {
    timeZone: 'Europe/Rome',
  });
  return timeStamp === 'Invalid Date' ? '' : timeStamp ?? '';
};

// Update the occupancy of a parking spot
export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.log('EVENT: \n' + JSON.stringify(event, null, 2));

  try {
    const command = new ScanCommand({ TableName: tableName });
    const data = (await docClient.send(command)) as ScanCommandOutput;
    const items = data?.Items ?? [];

    // Scan returns an empty array - DB is empty !
    if (!items.length) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'no parking spots found!' }),
      };
    }

    const parkingData = items.map((item) => {
      return {
        parkingSpot: +item.parkingSpot,
        vrn: item.VRN ?? '',
        startTime: formatTimeOrBlank(item.startTime),
      };
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Scan completed',
        data: parkingData,
      }),
    };
  } catch (error) {
    console.error('Unknown error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal Server Error' }),
    };
  }
};
