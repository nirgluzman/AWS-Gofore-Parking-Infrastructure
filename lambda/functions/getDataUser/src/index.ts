// https://docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/javascript_dynamodb_code_examples.html
// https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBMapper.DataTypes.html

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  ScanCommand,
  GetCommand,
  ScanCommandOutput,
  GetCommandOutput,
} from '@aws-sdk/lib-dynamodb';

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

// environment variables
const region = process.env.REGION;
const tableName = process.env.TABLE_NAME;

// initialize DynamoDB client
const ddbClient = new DynamoDBClient({ region });

// initialize DynamoDB DocumentClient
const docClient = DynamoDBDocumentClient.from(ddbClient);

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  console.log('EVENT: \n' + JSON.stringify(event, null, 2));

  try {
    const type = event.pathParameters?.type;

    if (type === '' || (type !== 'all' && isNaN(Number(type)))) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Invalid request' }),
      };
    }

    if (type === 'all') {
      // status of ALL parking spots.
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
          freeSpot: !item.VRN,
        };
      });

      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'Scan completed',
          data: parkingData,
        }),
      };
    } else {
      // status of a SPECIFIC parkingSpot
      const command = new GetCommand({
        TableName: tableName,
        Key: {
          parkingSpot: Number(type),
        },
      });
      const data = (await docClient.send(command)) as GetCommandOutput;

      if (!data.Item) {
        return {
          statusCode: 400,
          body: JSON.stringify({ message: 'parking spot is not valid!' }),
        };
      }

      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'GetItem completed',
          data: { freeSpot: !data.Item.VRN },
        }),
      };
    }
  } catch (error) {
    console.error('Unknown error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal Server Error' }),
    };
  }
};
